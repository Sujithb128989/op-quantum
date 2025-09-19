# Live Demonstration Guide

This file contains the step-by-step commands and actions for your live presentation.

---

### **Part 1: Initial Setup (Do this before the presentation starts)**

1.  **Open two separate terminal windows.** All commands should be run from the root of the `op-quantum` project directory.

2.  **In Terminal 1, start Server A (the "classic" server):**
    ```bash
    bash pqc-project/start_server_a.sh
    ```
    *This terminal will now be busy running the server. Leave it open.*

3.  **In Terminal 2, start Server B (the PQC-hardened server):**
    ```bash
    bash pqc-project/start_server_b.sh
    ```
    *This terminal will also be busy. Leave it open.*

4.  **Find your server's IP address.** You will need this for the attacker script and for accessing the websites in your browser.
    ```bash
    hostname -I
    ```
    *(Use the IP address that appears, for example `192.168.1.100`, in all the steps below where you see `<YOUR_SERVER_IP>`.)*

---

### **Part 2: The Live Demonstration Steps**

#### **Demo 1: The Database Heist (SQL Injection)**

1.  **Open a third terminal window.** This will be your "attacker" terminal.

2.  **Run the exploit against Server A:**
    ```bash
    python3 pqc-project/attacker/sql_injector.py https://<YOUR_SERVER_IP>:8443
    ```
    *   **What to show:** Point out to the audience that the script successfully found table names (`users`, `messages`) and dumped user data.

3.  **Run the same exploit against Server B:**
    ```bash
    python3 pqc-project/attacker/sql_injector.py https://<YOUR_SERVER_IP>:9443
    ```
    *   **What to show:** Point out that the script *also* succeeds here. This is the key point of this demo: PQC doesn't fix all types of vulnerabilities.

---

#### **Demo 2: Protecting Data in Motion (Data-in-Transit)**

1.  **Open your web browser.**

2.  **Inspect Server A's certificate:**
    *   Go to `https://<YOUR_SERVER_IP>:8443`.
    *   Click the **lock icon** in the address bar -> "Connection is secure" -> "Certificate is valid".
    *   **What to show:** Point to the "Signature Algorithm". It will be a standard one, like `RSA`.

3.  **Inspect Server B's certificate:**
    *   Go to `https://<YOUR_SERVER_IP>:9443`.
    *   Click the **lock icon** -> "Connection is secure" -> "Certificate is valid".
    *   **What to show:** Point to the "Signature Algorithm". It will have a PQC name, like **`Dilithium3`**. This is your proof of quantum-resistant protection for data in transit.

---

#### **Demo 3: Protecting Data at Rest**

1.  **Send messages from the browser:**
    *   Go to Server A's messaging page (`https://<YOUR_SERVER_IP>:8443/messaging`). Send a message like: `Hello classic server`.
    *   Go to Server B's messaging page (`https://<YOUR_SERVER_IP>:9443/messaging`). Send a message like: `Hello PQC server`.

2.  **Go back to your "attacker" terminal** (or any other free terminal).

3.  **Inspect the database directly:**
    *   Run the following command to open the database file:
        ```bash
        sqlite3 pqc-project/database.db
        ```
    *   Once you are inside the `sqlite>` prompt, run this command to see the messages:
        ```sql
        SELECT sender, message_text FROM messages;
        ```
    *   To exit the database viewer, type:
        ```sql
        .quit
        ```

4.  **What to show:** The output in your terminal. You will clearly see:
    *   The message from Server A (`Hello classic server`) in plain, readable text.
    *   The message from Server B will be shown as unreadable binary data (it might look like random characters or a `BLOB`). This is your proof of quantum-resistant protection for data at rest.
