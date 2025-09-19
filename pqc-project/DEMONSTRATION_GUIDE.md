# Live Demonstration Guide

This file contains the step-by-step commands and actions for a live demonstration of this project.

---
**IMPORTANT NOTE ON AUDIO:** For the audio feature to work, you must provide your own `gitgud.mp3` sound file. Place this file inside the `pqc-project/app/static/audio/` directory before starting the servers.
---

### **Part 1: Initial Setup**

1.  **Open two separate terminal windows.** All commands should be run from the root of the `op-quantum` project directory.

2.  **In Terminal 1, start Server A (the "classic" server):**
    ```bash
    bash pqc-project/start_server_a.sh
    ```
    *This terminal will now be occupied by the server process.*

3.  **In Terminal 2, start Server B (the PQC-hardened server):**
    ```bash
    bash pqc-project/start_server_b.sh
    ```
    *This terminal will also be occupied by a server process.*

4.  **Obtain the server's IP address.** This is required for the attack scripts and for browser access.
    ```bash
    hostname -I
    ```
    *The resulting IP address (e.g., `192.168.1.100`) should be used in place of `<YOUR_SERVER_IP>` in subsequent steps.*

---

### **Part 2: Demonstration Steps**

#### **Demo 1: Database Exploit (SQL Injection)**

1.  **Open a third terminal window** for running the attacker script.

2.  **Execute the exploit against Server A:**
    ```bash
    python3 pqc-project/attacker/sql_injector.py https://<YOUR_SERVER_IP>:8443
    ```
    *   **Verification:** The script output will show that it successfully found table names (`users`, `messages`) and dumped user data.

3.  **Execute the same exploit against Server B:**
    ```bash
    python3 pqc-project/attacker/sql_injector.py https://<YOUR_SERVER_IP>:9443
    ```
    *   **Verification:** The script will also succeed against Server B. This is an intentional part of the demonstration, designed to highlight that PQC protects against cryptographic threats, not all application-layer vulnerabilities.

---

#### **Demo 2: Data-in-Transit Protection (TLS)**

1.  **Open a web browser.**

2.  **Inspect Server A's certificate:**
    *   Navigate to `https://<YOUR_SERVER_IP>:8443`.
    *   Inspect the TLS certificate via the browser's security details (usually by clicking the lock icon).
    *   **Verification:** The "Signature Algorithm" will be a standard algorithm, such as `RSA`.

3.  **Inspect Server B's certificate:**
    *   Navigate to `https://<YOUR_SERVER_IP>:9443`.
    *   Inspect the TLS certificate.
    *   **Verification:** The "Signature Algorithm" will be a PQC algorithm, such as **`Dilithium3`**. This demonstrates quantum-resistant protection for data in transit.

---

#### **Demo 3: Data-at-Rest Protection (Database)**

1.  **Send messages from the browser:**
    *   From Server A's messaging page (`https://<YOUR_SERVER_IP>:8443/messaging`), send a message (e.g., `classic message`).
    *   From Server B's messaging page (`https://<YOUR_SERVER_IP>:9443/messaging`), send a message (e.g., `pqc message`).

2.  **From a terminal, inspect the database directly:**
    *   Open the database file:
        ```bash
        sqlite3 pqc-project/database.db
        ```
    *   At the `sqlite>` prompt, query the messages table:
        ```sql
        SELECT sender, message_text FROM messages;
        ```
    *   Exit the database viewer by typing `.quit`.

3.  **Verification:** The terminal output will show:
    *   The message from Server A is stored in readable plain text.
    *   The message from Server B is stored as unreadable binary data (a `BLOB`), demonstrating quantum-resistant protection for data at rest.
