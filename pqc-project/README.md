# PQC Demonstration Suite: Data-in-Transit and Data-at-Rest

## 1. Project Objective

This project provides a hands-on demonstration of Post-Quantum Cryptography (PQC) applied to two critical areas of web security:
1.  **Data-in-Transit:** Protecting TLS connections from quantum-era threats using PQC-hybrid key exchange.
2.  **Data-at-Rest:** Protecting sensitive data in a database using PQC-based encryption.

The demonstration contrasts a **standard server (Server A)** with a **PQC-hardened server (Server B)** and showcases how they respond to various test scenarios.

## 2. How to Run the Demonstration

**Prerequisite:** You must be using a **Debian-based Linux** environment (e.g., Kali, Ubuntu) running in WSL.

---

### Phase 1: Full System Setup

This phase will install all dependencies and build both servers.

1.  **Clone the Repository:**
    ```bash
    git clone https://github.com/Sujithb128989/op-quantum.git
    cd op-quantum
    ```

2.  **Run the Master Setup Script:** This single script will perform all necessary setup steps, including installing dependencies, making scripts executable, building both servers, setting up the Python environment, generating certificates, and initializing the database. It will take a very long time.
    ```bash
    bash pqc-project/run_full_setup.sh
    ```

---

### Phase 2: Running the Demonstration

For the demonstration, you will need **three separate terminal windows** open at the `op-quantum/pqc-project` root directory.

**Terminal 1: Start the VULNERABLE Server A**
1.  Activate the Python Environment: `source ../venv/bin/activate`
2.  Run the start script:
    ```bash
    ./start_server_a.sh
    ```
    *This terminal will now be occupied by the Python backend for Server A.*

**Terminal 2: Start the SECURE Server B**
1.  Activate the Python Environment: `source ../venv/bin/activate`
2.  Run the start script:
    ```bash
    ./start_server_b.sh
    ```
    *This terminal will now be occupied by the Python backend for Server B.*

**Terminal 3 (or External Machine): Run the Test Scripts**
1.  **Find your Kali Linux IP Address:** You will need this if you are testing from a different machine. In a terminal on your Kali machine, run: `hostname -I`
2.  **Activate the Python Environment** (if running locally): `source ../venv/bin/activate`
3.  **Follow the test narrative below**, replacing `<YOUR_KALI_IP>` with the address from the previous step.

---

### Phase 3: The Demonstration Narrative

#### 1. Input Validation Test on Server A

*   **Goal:** Demonstrate the effect of improper server-side input validation.
*   **Action:** Run the validation test script against Server A's full URL.
    ```bash
    # Replace <YOUR_KALI_IP> with your actual IP address
    python3 attacker/sql_injector.py https://<YOUR_KALI_IP>:8443
    ```
*   **Expected Outcome:** The script will retrieve more data than intended.

#### 2. High-Traffic Test on Server A ("Hard Crash")

*   **Goal:** Demonstrate the server crashing completely after being overwhelmed by requests.
*   **Action:** Run the load testing script against Server A's URL.
    ```bash
    # Replace <YOUR_KALI_IP> with your actual IP address
    python3 attacker/HULK-LORIS-ULTRA.py https://<YOUR_KALI_IP>:8443/ -w 5000 -d 120
    ```
*   **Expected Outcome:** After approximately 5,000 requests are processed by the backend, the Python application will **terminate the Nginx process**. You will see the `start_server_a.sh` script exit in Terminal 1.

#### 3. Input Validation Test on Server B

*   **Goal:** Show that the secure server correctly validates user input.
*   **Action:** Run the same validation test script against Server B's URL.
    ```bash
    # Replace <YOUR_KALI_IP> with your actual IP address
    python3 attacker/sql_injector.py https://<YOUR_KALI_IP>:9443
    ```
*   **Expected Outcome:** The script will fail to retrieve any data.

#### 4. PQC-Encrypted Messaging on Server B

*   **Goal:** Demonstrate that messages are protected at-rest using PQC.
*   **Action:** Use a web browser on your Windows host machine to navigate to the UI at `http://<YOUR_KALI_IP>:5000`. Send messages between two users (e.g., `alice` and `bob`) with Server B selected as the backend.
*   **Verification:** Examine the `messages` table in the `database.db` file.
*   **Expected Outcome:** The message content will be stored as unreadable binary data.

#### 5. High-Traffic Test on Server B ("Hard Crash")

*   **Goal:** Demonstrate the secure server also crashing when overwhelmed.
*   **Action:** Run the load testing script against Server B.
    ```bash
    # Replace <YOUR_KALI_IP> with your actual IP address
    python3 attacker/HULK-LORIS-ULTRA.py https://<YOUR_KALI_IP>:9443/ -w 5000 -d 120
    ```
*   **Expected Outcome:** The same as Server A. After ~5,000 requests, the Python backend will terminate the Nginx process.
