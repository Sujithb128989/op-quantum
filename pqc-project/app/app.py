import sqlite3
import hashlib
import argparse
import os
import signal
import sys
import threading
from flask import Flask, request, session, redirect, url_for, render_template, g, jsonify

# --- Local Imports ---
from pqc_crypto import PQCrypto

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
    if 'username' in session:
        return f'''
            <h1>Welcome, {session['username']}!</h1>
            <p>Application running in <strong>{APP_MODE}</strong> mode.</p>
            <a href="/search">Search for Users</a><br>
            <a href="/messaging">Secure Messenger</a><br>
            <a href="/logout">Logout</a>
        '''
    return '<h1>Welcome!</h1><p>You are not logged in.</p><a href="/login">Login</a> | <a href="/register">Register</a>'

@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        password_hash = hashlib.sha256(password.encode()).hexdigest()

        db = get_db()
        try:
            db.execute("INSERT INTO users (username, password_hash) VALUES (?, ?)", (username, password_hash))
            db.commit()
            return redirect(url_for('login'))
        except sqlite3.IntegrityError:
            return "Username already exists.", 400
    return '''
        <form method="post">
            Username: <input type="text" name="username"><br>
            Password: <input type="password" name="password"><br>
            <input type="submit" value="Register">
        </form>
    '''

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        password_hash = hashlib.sha256(password.encode()).hexdigest()

        db = get_db()
        user = db.execute("SELECT * FROM users WHERE username = ? AND password_hash = ?", (username, password_hash)).fetchone()

        if user:
            session['username'] = user['username']
            return redirect(url_for('index'))
        else:
            return "Invalid credentials.", 401
    return '''
        <form method="post">
            Username: <input type="text" name="username"><br>
            Password: <input type="password" name="password"><br>
            <input type="submit" value="Login">
        </form>
    '''

@app.route('/logout')
def logout():
    session.pop('username', None)
    return redirect(url_for('index'))

@app.route('/search', methods=['GET', 'POST'])
def search():
    if 'username' not in session:
        return redirect(url_for('login'))

    results = []
    if request.method == 'POST':
        search_term = request.form['search_term']
        db = get_db()

        if APP_MODE == "vulnerable":
            query = f"SELECT username FROM users WHERE username LIKE '%{search_term}%'"
            results = db.execute(query).fetchall()
        else: # secure mode
            query = "SELECT username FROM users WHERE username LIKE ?"
            results = db.execute(query, ('%' + search_term + '%',)).fetchall()

    return f'''
        <h1>Search for Users</h1>
        <form method="post">
            <input type="text" name="search_term" placeholder="Enter username...">
            <input type="submit" value="Search">
        </form>
        <h2>Results:</h2>
        <ul>
            {"".join(f"<li>{row['username']}</li>" for row in results)}
        </ul>
        <a href="/">Back to Home</a>
    '''

@app.route('/messaging')
def messaging():
    if 'username' not in session:
        return redirect(url_for('login'))
    return render_template('messaging.html')

# --- API Endpoints for Messaging GUI ---
@app.route('/api/get_current_user')
def get_current_user():
    if 'username' not in session:
        return jsonify({'error': 'Not logged in'}), 401
    return jsonify({'username': session['username']})

@app.route('/api/get_users')
def get_users():
    if 'username' not in session:
        return jsonify({'error': 'Not logged in'}), 401
    db = get_db()
    users = db.execute("SELECT username FROM users").fetchall()
    return jsonify([dict(row) for row in users])

@app.route('/api/get_messages')
def get_messages():
    if 'username' not in session:
        return jsonify({'error': 'Not logged in'}), 401
    recipient = request.args.get('recipient')
    if not recipient:
        return jsonify({'error': 'Recipient not specified'}), 400
    db = get_db()
    current_user = session['username']
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
    recipient = data.get('recipient')
    message_text = data.get('message_text')
    if not recipient or not message_text:
        return jsonify({'error': 'Missing recipient or message text'}), 400
    db = get_db()
    sender = session['username']
    encrypted_key = None
    final_message_text = message_text.encode('utf-8')
    if APP_MODE == 'secure':
        encrypted_key, final_message_text = pqc_crypto_instance.encrypt(final_message_text)
    db.execute("INSERT INTO messages (sender, recipient, message_text, encrypted_key) VALUES (?, ?, ?, ?)", (sender, recipient, final_message_text, encrypted_key))
    db.commit()
    return jsonify({'status': 'success'})

# --- Main Application Runner ---
def main():
    global APP_MODE, pqc_crypto_instance, NGINX_PID_FILE

    parser = argparse.ArgumentParser(description="Run the backend web application.")
    parser.add_argument('--mode', choices=['vulnerable', 'secure'], required=True, help="The mode to run the application in.")
    parser.add_argument('--port', type=int, required=True, help="The port to run the application on.")
    parser.add_argument('--nginx-pid-file', help="Path to the Nginx PID file to monitor and terminate.")

    args = parser.parse_args()
    APP_MODE = args.mode
    NGINX_PID_FILE = args.nginx_pid_file

    if APP_MODE == 'secure':
        pqc_crypto_instance = PQCrypto()

    print(f"=========================================")
    print(f"Starting backend server in '{APP_MODE}' mode on port {args.port}")
    if NGINX_PID_FILE:
        print(f"Monitoring Nginx PID file: {NGINX_PID_FILE}")
        print(f"Server will terminate after {REQUEST_LIMIT} requests.")
    print(f"Database path: {DB_PATH}")
    print(f"=========================================")

    app.run(host='127.0.0.1', port=args.port, debug=True)

if __name__ == '__main__':
    main()
