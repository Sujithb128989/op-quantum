# PQC Demonstration Suite: Data-in-Transit and Data-at-Rest

## 1. Project Objective

This project provides a hands-on demonstration of Post-Quantum Cryptography (PQC). The demonstration contrasts a **standard server (Server A)** with a **PQC-enabled server (Server B)**.

For the purpose of a focused demonstration, both servers share the same application-level vulnerabilities. The **only** intended difference between them is that Server B uses PQC to protect data-in-transit (via TLS) and data-at-rest (in the database).

The user interface has been redesigned with a theme inspired by the game *Hollow Knight: Silksong*.

## 2. How to Run the Demonstration

**Prerequisite:** You must be using a **Debian-based Linux** environment (e.g., Kali, Ubuntu) running in WSL.

**Working Directory:** All commands must be run from the **root of the `op-quantum` repository**.

---

### Phase 1: Full System Setup

This phase installs dependencies, builds both servers, and sets up the application.
```bash
bash pqc-project/run_full_setup.sh
```

---

### Phase 2: Running the Demonstration

For the demonstration, you will need **three separate terminal windows**, all in the `op-quantum` root directory.

**Terminal 1: Start Server A**
```bash
bash pqc-project/start_server_a.sh
```
*This terminal will now be occupied by the backend for Server A. Leave it running.*

**Terminal 2: Start Server B**
```bash
bash pqc-project/start_server_b.sh
```
*This terminal will now be occupied by the backend for Server B. Leave it running.*

---

### Phase 3: The Demonstration Narrative

#### 1. Application Vulnerability Test (SQL Injection)

*   **Goal:** Demonstrate that both servers share an identical application-layer vulnerability. This test isolates PQC as a cryptographic defense, not a fix for all security issues.
*   **Action on Server A:**
    ```bash
    python3 pqc-project/attacker/sql_injector.py https://<YOUR_KALI_IP>:8443
    ```
*   **Expected Outcome on Server A:** The script will successfully dump table names and user data from the database. The retrieved data will be in plain text.
*   **Action on Server B:**
    ```bash
    python3 pqc-project/attacker/sql_injector.py https://<YOUR_KALI_IP>:9443
    ```
*   **Expected Outcome on Server B:** The script will also succeed. This is intentional. The key difference is that any PQC-encrypted data in the database remains secure, even when retrieved.

#### 2. PQC-Encrypted Messaging (Data-at-Rest)

*   **Goal:** Demonstrate that messages stored by Server B are protected at-rest using PQC.
*   **Action:** In a web browser, send a message to "gitgud" via Server B's interface.
*   **Verification:** Examine the `database.db` file (`sqlite3 pqc-project/database.db` then `SELECT * FROM messages;`).
*   **Expected Outcome:** The message content sent via Server B will be unreadable binary data, even after being exfiltrated via the SQL injection.

#### 3. PQC-Encrypted Connection (Data-in-Transit)

*   **Goal:** Demonstrate that Server B uses PQC to protect the TLS connection.
*   **Action:** In a web browser, inspect the TLS certificate for Server B.
*   **For detailed instructions, see the file `pqc-project/DATA_IN_TRANSIT_EXPLAINER.md`**.

#### 4. High-Traffic Test ("Hard Crash")

*   **Goal:** Demonstrate the servers crashing after being overwhelmed by traffic.
*   **Action (Server A):**
    ```bash
    python3 pqc-project/attacker/HULK-LORIS-ULTRA.py https://<YOUR_KALI_IP>:8443/ -w 5000 -d 120
    ```
*   **Action (Server B):**
    ```bash
    python3 pqc-project/attacker/HULK-LORIS-ULTRA.py https://<YOUR_KALI_IP>:9443/ -w 5000 -d 120
    ```
*   **Expected Outcome:** The Nginx process will be terminated. The script in the corresponding terminal will exit.
