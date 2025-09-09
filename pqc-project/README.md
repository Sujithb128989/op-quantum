# PQC Demonstration Suite: Data-in-Transit and Data-at-Rest

## 1. Project Objective

This project provides a hands-on demonstration of Post-Quantum Cryptography (PQC) applied to two critical areas of web security:

1.  **Data-in-Transit:** Protecting data as it travels over the network using PQC in the TLS handshake.
2.  **Data-at-Rest:** Protecting data stored in a database using a PQC-hybrid encryption scheme.

The demonstration follows a sequential narrative, first showcasing the secure application, then revealing the vulnerabilities of a standard server ("Server A"), and finally proving the security guarantees of the PQC-hardened server ("Server B").

### Further Reading:
- For a technical explanation of the cryptography used, see `PQC_EXPLAINER.md`.
- For thoughts on applying this to real-world systems, see `CONCEPTUAL_IMPLEMENTATION.md`.

---

## 2. How to Run the Demonstration

**Prerequisite:** You must have a **Windows** machine with **MSYS2** installed. All commands below should be run from the **MSYS2 MINGW64** terminal, starting from the `pqc-project` root directory.

### Phase 1: Initial Project Setup

These steps only need to be performed once. **Please perform them in this exact order.**

1.  **Install Dependencies:** Run the setup script to install all required compilers and tools.
    ```bash
    ./setup_msys2.sh
    ```
    **IMPORTANT:** After this script finishes, you **MUST close and reopen** the MSYS2 terminal before proceeding to the next step. This allows the terminal to recognize the newly installed programs.
2.  **Build Both Servers:** Compile the Nginx binaries and the underlying PQC libraries. This is a critical step that must be done before installing the Python packages. This will take a significant amount of time.
    ```bash
    (cd server_a && ./build_standard_server.sh)
    (cd server_b && ./build_pqc_server.sh)
    ```
2.  **Install Python Libraries:** Install the necessary Python packages. We use an absolute path to the python executable to avoid `PATH` issues.
    ```bash
    /mingw64/bin/python -m pip install -r app/requirements.txt
    /mingw64/bin/python -m pip install -r attacker/requirements.txt
    ```
4.  **Generate Certificates:** Create the self-signed certificates for both servers. This requires the PQC-enabled OpenSSL that was just built.
    ```bash
    ./generate_certs.sh
    ```

---

### Phase 2: Showcase the Secure Application (Server B)

First, we'll see the fully functional, secure application in action.

1.  **Reset and Start Server B:**
    *   Run the database setup script to create a fresh database: `python database_setup.py`
    *   In a terminal, start the backend app in **secure** mode: `python app/app.py --mode secure --port 8081`
    *   In a *new* terminal, start the PQC-Nginx server: `./server_b/nginx/sbin/nginx.exe -p $(pwd)/ -c server_b/nginx.conf`

2.  **Access the GUI:** With Server B running, open a web browser and navigate to `https://localhost:9443/`.
3.  **Login and Explore:** Register a new user or log in as one of the defaults (e.g., `alice`/`password123`). Navigate to the "Secure Messenger" page.
4.  **Send Messages:** Send messages between users and observe the "Encryption Status" visualization, which provides a tangible representation of the PQC-hybrid encryption protecting your data at rest.
5.  **Shutdown:** When finished, stop the Nginx server (`./server_b/nginx/sbin/nginx.exe -s stop`) and the backend app (`Ctrl+C`).

---

### Phase 3: Demonstrate Server A's Vulnerabilities

Now, we rewind to a traditional, insecure server to see how it fails.

1.  **Reset and Start Server A:**
    *   Run the database setup script again for a clean state: `python database_setup.py`
    *   In a terminal, start the backend app in **vulnerable** mode: `python app/app.py --mode vulnerable --port 8080`
    *   In a *new* terminal, start the Nginx server: `./server_a/nginx/sbin/nginx.exe -p $(pwd)/ -c server_a/nginx.conf`

2.  **Perform Attacks on Server A:**
    *   Follow the detailed instructions in `attacker/ATTACK_GUIDE.md` to perform the **SQL Injection** and **DDoS** attacks on Server A.
    *   You will observe that the database is successfully exfiltrated in **plaintext**.
    *   When finished, stop the Nginx server (`./server_a/nginx/sbin/nginx.exe -s stop`) and the backend app (`Ctrl+C`).

---

### Phase 4: Prove Server B's Security Under Attack

Finally, we prove Server B's security by running the same attacks against it.

1.  **Start Server B Again:** Follow the same steps as in Phase 2 to start Server B and its backend.

2.  **Perform Attacks on Server B:**
    *   Follow the detailed instructions in `attacker/ATTACK_GUIDE.md` to perform the same attacks on Server B.
    *   You will observe that the stolen database data is **encrypted and useless**, and that the network traffic is protected by PQC-TLS.
    *   When finished, shut down the servers. This concludes the demonstration.
