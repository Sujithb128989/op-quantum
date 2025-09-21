import sqlite3
import argparse
import os
import signal
import sys
import threading
import markdown
import random
import string
from flask import Flask, request, session, redirect, url_for, render_template, g, jsonify

# --- Local Imports ---
# Defer PQC import until we know we need it

# --- Application Setup ---
app = Flask(__name__)
app.secret_key = os.urandom(24)

# --- Global Configuration ---
APP_MODE = "secure"
DB_PATH = os.path.join(os.path.dirname(__file__), '..', 'database.db')
pqc_crypto_instance = None
NGINX_PID_FILE = None
REQUEST_COUNT = 0
REQUEST_LIMIT = 5000
counter_lock = threading.Lock()
OTHER_SERVER_URL = None

# --- Crash Logic ---
@app.before_request
def check_request_limit():
    global REQUEST_COUNT
    if NGINX_PID_FILE:
        with counter_lock:
            REQUEST_COUNT += 1
            if REQUEST_COUNT >= REQUEST_LIMIT:
                try:
                    with open(NGINX_PID_FILE, 'r') as f:
                        pid = int(f.read().strip())
                    print(f"!!!!!! Request limit of {REQUEST_LIMIT} reached. Terminating Nginx (PID: {pid})... !!!!!!", file=sys.stderr)
                    os.kill(pid, signal.SIGKILL)
                except Exception as e:
                    print(f"!!!!!! Could not terminate Nginx process: {e} !!!!!!", file=sys.stderr)
            elif REQUEST_COUNT % 100 == 0:
                print(f"[INFO] Request count: {REQUEST_COUNT}/{REQUEST_LIMIT}", file=sys.stderr)

# --- Database Helper ---
def get_db():
    db = getattr(g, '_database', None)
    if db is None:
        db = g._database = sqlite3.connect(DB_PATH)
        db.row_factory = sqlite3.Row
    return db

@app.teardown_appcontext
def close_connection(exception):
    db = getattr(g, '_database', None)
    if db is not None:
        db.close()

# --- Routes ---
@app.route('/')
def index():
    return render_template('index.html', app_mode=APP_MODE)

@app.route('/messaging')
def messaging():
    if 'username' not in session:
        session['username'] = ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))
    # Pass an empty list for search results on default page load
    return render_template('messaging.html', user_search_results=[], app_mode=APP_MODE)

@app.route('/search', methods=['POST'])
def search():
    """
    This search function is intentionally vulnerable to SQL injection.
    It is for educational and demonstration purposes only.
    """
    if 'username' not in session:
        session['username'] = ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))

    search_term = request.form.get('query', '')
    db = get_db()

    # --- INTENTIONAL VULNERABILITY ---
    # The following code constructs a SQL query using unsafe string concatenation.
    # This is the source of the SQL injection vulnerability.
    # In a real application, you should ALWAYS use parameterized queries.
    # For example: db.execute("... WHERE username LIKE ?", ('%' + search_term + '%',))
    vulnerable_query = "SELECT username, password FROM users WHERE username LIKE '%" + search_term + "%'"
    # --- END INTENTIONAL VULNERABILITY ---

    results = db.execute(vulnerable_query).fetchall()

    # Render the messaging page, passing the search results to be displayed in the user list.
    return render_template('messaging.html', user_search_results=results, app_mode=APP_MODE)

# --- API Endpoints for Messaging GUI ---
@app.route('/api/get_current_user')
def get_current_user():
    if 'username' not in session:
        return jsonify({'error': 'Not logged in'}), 401
    return jsonify({'username': session['username']})

@app.route('/api/get_messages')
def get_messages():
    if 'username' not in session:
        return jsonify({'error': 'Not logged in'}), 401

    db = get_db()
    current_user = session['username']
    recipient = "gitgud" # Hardcoded recipient

    messages_query = "SELECT sender, recipient, message_text, encrypted_key, timestamp FROM messages WHERE (sender = ? AND recipient = ?) OR (sender = ? AND recipient = ?) ORDER BY timestamp DESC"
    messages_rows = db.execute(messages_query, (current_user, recipient, recipient, current_user)).fetchall()

    messages = []
    for row in messages_rows:
        message_data = dict(row)
        if APP_MODE == 'secure' and message_data['encrypted_key'] is not None:
            try:
                decrypted_text = pqc_crypto_instance.decrypt(message_data['encrypted_key'], message_data['message_text'])
                message_data['message_text'] = decrypted_text.decode('utf-8', 'replace')
            except Exception:
                message_data['message_text'] = "[Decryption Error: Unable to read message]"
        else:
            if isinstance(message_data['message_text'], bytes):
                message_data['message_text'] = message_data['message_text'].decode('utf-8', 'replace')
        messages.append(message_data)

    return jsonify(messages)

@app.route('/api/send_message', methods=['POST'])
def send_message():
    if 'username' not in session:
        return jsonify({'error': 'Not logged in'}), 401

    data = request.get_json()
    recipient = "gitgud" # Hardcoded recipient
    message_text = data.get('message_text')

    if not message_text:
        return jsonify({'error': 'Missing message text'}), 400

    db = get_db()
    sender = session['username']
    encrypted_key = None
    final_message_text = message_text.encode('utf-8')

    if APP_MODE == 'secure':
        encrypted_key, final_message_text = pqc_crypto_instance.encrypt(final_message_text)

    db.execute("INSERT INTO messages (sender, recipient, message_text, encrypted_key) VALUES (?, ?, ?, ?)", (sender, recipient, final_message_text, encrypted_key))
    db.commit()

    # Forward the message to the other server
    if OTHER_SERVER_URL and not request.headers.get('X-Forwarded-Message'):
        try:
            import requests
            requests.post(
                f"{OTHER_SERVER_URL}/api/send_message",
                json={'message_text': message_text},
                headers={'X-Forwarded-Message': 'true'}
            )
        except Exception as e:
            print(f"Error forwarding message: {e}", file=sys.stderr)

    return jsonify({'status': 'success'})

# --- Main Application Runner ---
def main():
    global APP_MODE, pqc_crypto_instance, NGINX_PID_FILE, OTHER_SERVER_URL

    parser = argparse.ArgumentParser(description="Run the backend web application.")
    parser.add_argument('--mode', choices=['vulnerable', 'secure'], required=True, help="The mode to run the application in.")
    parser.add_argument('--port', type=int, required=True, help="The port to run the application on.")
    parser.add_argument('--nginx-pid-file', help="Path to the Nginx PID file to monitor and terminate.")
    parser.add_argument('--other-server-url', help="URL of the other server for cross-communication.")

    args = parser.parse_args()
    APP_MODE = args.mode
    NGINX_PID_FILE = args.nginx_pid_file
    OTHER_SERVER_URL = args.other_server_url

    if APP_MODE == 'secure':
        from pqc_crypto import PQCrypto
        pqc_crypto_instance = PQCrypto()

    print(f"=========================================")
    print(f"Starting backend server in '{APP_MODE}' mode on port {args.port}")
    if NGINX_PID_FILE:
        print(f"Monitoring Nginx PID file: {NGINX_PID_FILE}")
        print(f"Server will terminate after {REQUEST_LIMIT} requests.")
    if OTHER_SERVER_URL:
        print(f"Other server URL: {OTHER_SERVER_URL}")
    print(f"Database path: {DB_PATH}")
    print(f"=========================================")

    app.run(host='127.0.0.1', port=args.port, debug=True)

if __name__ == '__main__':
    main()
