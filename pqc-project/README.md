# PQC Demonstration Suite: Data-in-Transit and Data-at-Rest

## 1. Project Objective

This project provides a hands-on demonstration of Post-Quantum Cryptography (PQC) applied to two critical areas of web security:

1.  **Data-in-Transit:** Protecting data as it travels over the network using PQC in the TLS handshake.
2.  **Data-at-Rest:** Protecting data stored in a database using a PQC-hybrid encryption scheme.

The demonstration follows a sequential narrative, first showcasing the vulnerabilities of a standard server ("Server A") and then highlighting the security guarantees of a PQC-hardened server ("Server B").

### Key Demonstration Points:
- **Server A (The Past):** Is vulnerable to SQL Injection (leaking plaintext data) and can be taken down by a DoS attack.
- **Server B (The Future):** Protects against the same SQL Injection by encrypting the database at rest, rendering stolen data useless. It also protects network traffic with PQC, and includes a secure messaging application.

### Further Reading:
- For a technical explanation of the cryptography used, see `PQC_EXPLAINER.md`.
- For thoughts on applying this to real-world systems, see `CONCEPTUAL_IMPLEMENTATION.md`.

---

## 2. How to Run the Demonstration

**Prerequisite:** You must have a **Windows** machine with **MSYS2** installed. All commands below should be run from the **MSYS2 MINGW64** terminal, starting from the `pqc-project` root directory.

### Phase 1: Initial Project Setup

These steps only need to be performed once.

1.  **Install Dependencies:** Run the setup script to install all required compilers and tools.
    ```bash
    ./setup_msys2.sh
    ```
2.  **Install Python Libraries:** Install the necessary Python packages for the backend and attacker scripts.
    ```bash
    pip install -r app/requirements.txt
    pip install -r attacker/requirements.txt
    ```
3.  **Build Both Servers:** Compile the Nginx binaries for Server A and Server B. This will take a significant amount of time.
    ```bash
    (cd server_a && ./build_standard_server.sh)
    (cd server_b && ./build_pqc_server.sh)
    ```
4.  **Generate Certificates:** Create the self-signed certificates for both servers.
    ```bash
    ./generate_certs.sh
    ```

---

### Phase 2: Demonstrate Server A's Vulnerabilities

In this phase, we will see how a traditional server fails.

1.  **Reset and Start Server A:**
    *   Run the database setup script to create a fresh, **unencrypted** database: `python database_setup.py`
    *   In a terminal, start the backend app in **vulnerable** mode: `python app/app.py --mode vulnerable --port 8080`
    *   In a *new* terminal, start the Nginx server: `./server_a/nginx/sbin/nginx.exe -p $(pwd)/ -c server_a/nginx.conf`

2.  **Perform Attacks on Server A:**
    *   Follow the detailed instructions in `attacker/ATTACK_GUIDE.md` to perform the **SQL Injection** and **DDoS** attacks on Server A.
    *   You will observe that the database is successfully exfiltrated in plaintext.
    *   When finished, stop the Nginx server (`./server_a/nginx/sbin/nginx.exe -s stop`) and the backend app (`Ctrl+C`).

---

### Phase 3: Demonstrate Server B's Security

Now, we show how PQC provides robust protection.

1.  **Reset and Start Server B:**
    *   Run the database setup script again to ensure a clean state: `python database_setup.py`
    *   In a terminal, start the backend app in **secure** mode: `python app/app.py --mode secure --port 8081`
    *   In a *new* terminal, start the PQC-Nginx server: `./server_b/nginx/sbin/nginx.exe -p $(pwd)/ -c server_b/nginx.conf`

2.  **Perform Attacks on Server B:**
    *   Follow the detailed instructions in `attacker/ATTACK_GUIDE.md` to perform the same attacks on Server B.
    *   You will observe that the stolen database data is **encrypted and useless**.
    *   You will also verify that the TLS connection itself is protected by PQC.

---

### Phase 4: Showcase the Secure Application

1.  **Access the GUI:** With Server B still running, open a web browser and navigate to `https://localhost:9443/`.
2.  **Login and Explore:** Register a new user or log in as one of the defaults (e.g., `alice`/`password123`). Navigate to the "Secure Messenger" page.
3.  **Send Messages:** Send messages between users and observe the "Encryption Status" visualization, which provides a tangible representation of the PQC-hybrid encryption protecting your data at rest.
4.  **Shutdown:** When finished, stop the Nginx server (`./server_b/nginx/sbin/nginx.exe -s stop`) and the backend app (`Ctrl+C`).
