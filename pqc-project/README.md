# PQC Demonstration Suite: Data-in-Transit and Data-at-Rest

## 1. Project Objective

This project provides a hands-on demonstration of Post-Quantum Cryptography (PQC) applied to two critical areas of web security:
1.  **Data-in-Transit:** Protecting TLS connections from quantum-era threats using PQC-hybrid key exchange.
2.  **Data-at-Rest:** Protecting sensitive data in a database using PQC-based encryption.

The demonstration contrasts a **standard server (Server A)** with a **PQC-hardened server (Server B)** and showcases how they respond to various test scenarios.

## 2. How to Run the Demonstration

**Prerequisite:** You must be using a **Debian-based Linux** environment (e.g., Kali, Ubuntu) running in WSL. All commands should be run from a standard terminal, starting from the `pqc-project` root directory.

---

### Phase 1: Initial Project Setup

These steps only need to be performed once.

1.  **Install System Dependencies:** Run the setup script to install all required compilers and tools.
    ```bash
    ./setup_kali.sh
    ```

2.  **Build C-Libraries and Servers:** Compile the Nginx binaries and the underlying libraries. This will take a significant amount of time.
    ```bash
    (cd server_a && ./build_standard_server.sh)
    (cd server_b && ./build_pqc_server.sh)
    ```

3.  **Set Up Python Environment:** Create a virtual environment and install required packages.
    ```bash
    python3 -m venv venv
    source venv/bin/activate
    pip install -r app/requirements.txt
    pip install -r attacker/requirements.txt
    ```

4.  **Generate Certificates:** Create the self-signed certificates for both servers.
    ```bash
    ./generate_certs.sh
    ```
5.  **Initialize the Database:** Create and set up the SQLite database.
    ```bash
    python3 database_setup.py
    ```

---

### Phase 2: Running the Demonstration

For the demonstration, you will need **four separate terminal windows** open at the `pqc-project` root directory on your Kali machine.

**Terminal 1 & 2: Start the Servers**
1.  **Activate the Python Environment** in both terminals: `source venv/bin/activate`
2.  **In Terminal 1, start the VULNERABLE Server A:** `./start_server_a.sh`
3.  **In Terminal 2, start the SECURE Server B:** `./start_server_b.sh`

**Terminal 3: Launch the User Application**
1.  **Activate the Python Environment:** `source venv/bin/activate`
2.  **Launch the main web application:** `python3 app/app.py`
    *(This starts the UI on `http://127.0.0.1:5000`)*

**Terminal 4 (or External Machine): Run the Test Scripts**
1.  **Find your Kali Linux IP Address:** You will need this if you are testing from a different machine. In a terminal on your Kali machine, run:
    ```bash
    hostname -I
    ```
    *(This will print your IP address, for example: `172.28.11.123`)*
2.  **Activate the Python Environment** (if running locally): `source venv/bin/activate`
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

#### 2. High-Traffic Test on Server A

*   **Goal:** Observe server performance under a high-traffic load.
*   **Action:** Run the load testing script against Server A's URL.
    ```bash
    # Replace <YOUR_KALI_IP> with your actual IP address
    python3 attacker/HULK-LORIS-ULTRA.py https://<YOUR_KALI_IP>:8443/
    ```
*   **Expected Outcome:** The server will become unresponsive as it fails to handle the volume of requests.

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

#### 5. High-Traffic Test on Server B

*   **Goal:** Observe the PQC server's performance under the same high-traffic load.
*   **Action:** Run the load testing script against Server B.
    ```bash
    # Replace <YOUR_KALI_IP> with your actual IP address
    python3 attacker/HULK-LORIS-ULTRA.py https://<YOUR_KALI_IP>:9443/
    ```
*   **Expected Outcome:** The server will become unresponsive. This demonstrates that PQC protects against cryptographic threats, but not against network-level traffic floods.
