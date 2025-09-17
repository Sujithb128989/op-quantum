# PQC Demonstration Suite: Data-in-Transit and Data-at-Rest

## 1. Project Objective

This project provides a hands-on demonstration of Post-Quantum Cryptography (PQC). The demonstration contrasts a **standard server (Server A)** with a **PQC-hardened server (Server B)** and showcases how they respond to various test scenarios.

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

**Terminal 3 (or External Machine): Run the Test Scripts**
1.  **Find your Kali Linux IP Address** (if testing from another machine):
    ```bash
    hostname -I
    ```
2.  **Activate the Python Environment:**
    ```bash
    source venv/bin/activate
    ```
3.  **Follow the test narrative below**, replacing `<YOUR_KALI_IP>` with the address from the previous step.

---

### Phase 3: The Demonstration Narrative

#### 1. Input Validation Test on Server A

*   **Goal:** Demonstrate improper server-side input validation.
*   **Action:**
    ```bash
    python3 pqc-project/attacker/sql_injector.py https://<YOUR_KALI_IP>:8443
    ```
*   **Expected Outcome:** The script will retrieve user data from the database.

#### 2. High-Traffic Test on Server A ("Hard Crash")

*   **Goal:** Demonstrate the server crashing after being overwhelmed.
*   **Action:**
    ```bash
    python3 pqc-project/attacker/HULK-LORIS-ULTRA.py https://<YOUR_KALI_IP>:8443/ -w 5000 -d 120
    ```
*   **Expected Outcome:** After ~5,000 requests, the Nginx process will be terminated. The script in Terminal 1 will exit.

#### 3. Input Validation Test on Server B

*   **Goal:** Show the secure server correctly validates input.
*   **Action:**
    ```bash
    python3 pqc-project/attacker/sql_injector.py https://<YOUR_KALI_IP>:9443
    ```
*   **Expected Outcome:** The script will fail to retrieve any data.

#### 4. PQC-Encrypted Messaging on Server B

*   **Goal:** Demonstrate messages are protected at-rest using PQC.
*   **Action:** In a web browser, go to the application UI (which you can find by running `python3 pqc-project/app/app.py` in a new terminal after activating the venv) and send messages between users on Server B.
*   **Verification:** Examine the `database.db` file in the `pqc-project` directory.
*   **Expected Outcome:** The message content will be unreadable binary data.

#### 5. High-Traffic Test on Server B ("Hard Crash")

*   **Goal:** Demonstrate the secure server also crashing when overwhelmed.
*   **Action:**
    ```bash
    python3 pqc-project/attacker/HULK-LORIS-ULTRA.py https://<YOUR_KALI_IP>:9443/ -w 5000 -d 120
    ```
*   **Expected Outcome:** The Nginx process will be terminated. The script in Terminal 2 will exit.
