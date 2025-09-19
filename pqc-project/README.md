# PQC Demonstration Suite: Data-in-Transit and Data-at-Rest

## 1. Project Objective

This project provides a hands-on demonstration of Post-Quantum Cryptography (PQC). The demonstration contrasts a **standard server (Server A)** with a **PQC-hardened server (Server B)** and showcases how they respond to various test scenarios. The user interface has been redesigned with a theme inspired by the game *Hollow Knight: Silksong*.

## 2. How to Run the Demonstration

**Prerequisite:** You must be using a **Debian-based Linux** environment (e.g., Kali, Ubuntu) running in WSL.

**Working Directory:** All commands must be run from the **root of the `op-quantum` repository**.

---

### Phase 1: Full System Setup

This phase installs dependencies, builds both servers, and sets up the application.

1.  **Clone the Repository (if you haven't already):**
    ```bash
    git clone https://github.com/Sujithb128989/op-quantum.git
    cd op-quantum
    ```

2.  **Run the Master Setup Script:** This single script performs all necessary setup steps.
    ```bash
    bash pqc-project/run_full_setup.sh
    ```

---

### Phase 2: Running the Demonstration

For the demonstration, you will need **three separate terminal windows**, all in the `op-quantum` root directory.

**Terminal 1: Start Server A (Vulnerable)**
```bash
bash pqc-project/start_server_a.sh
```
*This terminal will now be occupied by the backend for Server A. Leave it running.*

**Terminal 2: Start Server B (Secure)**
```bash
bash pqc-project/start_server_b.sh
```
*This terminal will now be occupied by the backend for Server B. Leave it running.*

To enable cross-server communication, you can specify the URL of the other server when starting the applications. For example:

**Terminal 1 (Server A with cross-server communication):**
```bash
# In start_server_a.sh, you would modify the python command to include --other-server-url
# Example modification in start_server_a.sh:
# python3 pqc-project/app/app.py --mode vulnerable --port 8000 --other-server-url http://localhost:9000
```

**Terminal 2 (Server B with cross-server communication):**
```bash
# In start_server_b.sh, you would modify the python command to include --other-server-url
# Example modification in start_server_b.sh:
# python3 pqc-project/app/app.py --mode secure --port 9000 --other-server-url http://localhost:8000
```


### Phase 3: The Demonstration Narrative

#### 1. Input Validation Test (SQL Injection)

*   **Goal:** Demonstrate an SQL Injection vulnerability on Server A and how Server B prevents it.
*   **Action on Server A (Vulnerable):**
    ```bash
    python3 pqc-project/attacker/sql_injector.py https://<YOUR_KALI_IP>:8443
    ```
*   **Expected Outcome on Server A:** The script will successfully dump table names and user data from the database.
*   **Action on Server B (Secure):**
    ```bash
    python3 pqc-project/attacker/sql_injector.py https://<YOUR_KALI_IP>:9443
    ```
*   **Expected Outcome on Server B:** The script will also succeed here. This is intentional, to show that the *only* difference between the servers is the PQC encryption for messaging and data-in-transit, not other security features.

#### 2. PQC-Encrypted Messaging

*   **Goal:** Demonstrate messages are protected at-rest using PQC and can be sent between servers.
*   **Action:** In a web browser, go to the application UI for either server and send messages to "gitgud".
*   **Verification:** Examine the `database.db` file in the `pqc-project` directory.
*   **Expected Outcome:** The message content on Server B will be unreadable binary data.

#### 3. Data-in-Transit Protection

*   **Goal:** Demonstrate that Server B uses PQC to protect data in transit.
*   **Action:** In a web browser, inspect the TLS certificate for Server B.
*   **For detailed instructions, see the file `pqc-project/DATA_IN_TRANSIT_EXPLAINER.md`**.

#### 2. High-Traffic Test on Both Servers ("Hard Crash")

*   **Goal:** Demonstrate the servers crashing after being overwhelmed.
*   **Action (Server A):**
    ```bash
    python3 pqc-project/attacker/HULK-LORIS-ULTRA.py https://<YOUR_KALI_IP>:8443/ -w 5000 -d 120
    ```
*   **Action (Server B):**
    ```bash
    python3 pqc-project/attacker/HULK-LORIS-ULTRA.py https://<YOUR_KALI_IP>:9443/ -w 5000 -d 120
    ```
*   **Expected Outcome:** The Nginx process will be terminated. The script in the corresponding terminal will exit.
