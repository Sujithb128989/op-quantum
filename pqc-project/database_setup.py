import sqlite3
import os
import hashlib

DB_FILE = "database.db"

def create_database():
    """
    Creates and initializes the SQLite database with the required schema
    and some dummy data for demonstration.
    """
    db_path = os.path.join(os.getcwd(), DB_FILE)

    # Delete the old database file if it exists, to ensure a clean start.
    if os.path.exists(db_path):
        os.remove(db_path)
        print(f"Removed old database file: {db_path}")

    try:
        # Connect to the database (this will create the file)
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        print(f"Database created successfully at: {db_path}")

        # --- Create 'users' table ---
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL
        );
        """)
        print("Table 'users' created successfully.")

        # --- Create 'messages' table ---
        # We use BLOB types for message_text and encrypted_key to store raw binary data.
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sender TEXT NOT NULL,
            recipient TEXT NOT NULL,
            message_text BLOB NOT NULL,
            encrypted_key BLOB,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        );
        """)
        print("Table 'messages' created successfully.")

        # --- Insert Dummy Data ---
        # Passwords are hashed even in the "vulnerable" demo for a baseline of realism.
        users_to_add = [
            ('alice', 'password123'),
            ('bob', 'password456'),
            ('charlie', 'password789')
        ]

        for username, password in users_to_add:
            password_hash = hashlib.sha256(password.encode()).hexdigest()
            cursor.execute("INSERT INTO users (username, password_hash) VALUES (?, ?)", (username, password_hash))

        print(f"Added {len(users_to_add)} dummy users.")

        # Add a sample plaintext message for the vulnerable scenario (Server A).
        # For Server B, the app itself will handle adding encrypted messages.
        cursor.execute("""
        INSERT INTO messages (sender, recipient, message_text)
        VALUES (?, ?, ?)
        """, ('alice', 'bob', b'This is a plaintext message, easily readable if the database is stolen!'))
        print("Added one sample plaintext message.")

        # Commit the changes and close the connection
        conn.commit()
        conn.close()
        print("Database setup complete and connection closed.")

    except sqlite3.Error as e:
        print(f"Database error: {e}")
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    # Ensure the script runs from the project root directory
    if not os.path.basename(os.getcwd()) == 'pqc-project':
        # A simple check to see if we are in the right directory.
        # This is not foolproof but good for this project's purpose.
        if os.path.exists('pqc-project'):
             os.chdir('pqc-project')
        else:
             print("Please run this script from the root of the 'pqc-project' directory.")
             exit(1)

    create_database()
