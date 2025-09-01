# Server Testing & Analysis Guide

This guide provides the step-by-step instructions for running the test scripts against Server A and Server B to demonstrate their different security postures.

**Please follow the main `README.md` to ensure you are running the correct server for each phase.**

---

## Phase 1: Testing Server A (Standard Server)

Here, we will verify the vulnerabilities of the standard server setup.

### Test 1.1: Database Exfiltration via SQL Injection

This test uses the `sql_injector.py` script to demonstrate how a vulnerability in the web application can be used to leak the contents of the unencrypted database.

1.  **Run the script:** From the `pqc-project` root directory, execute the following command:
    ```bash
    python attacker/sql_injector.py https://localhost:8443
    ```

2.  **Expected Outcome:** The script will succeed and print the database contents, including table names and user data, to your console in **plaintext**. This demonstrates a catastrophic data breach.

### Test 1.2: Server Stress Test (DoS)

This test uses the `HULK-LORIS-ULTRA.py` script to demonstrate how the server's availability can be compromised.

1.  **Run the script:**
    ```bash
    python attacker/HULK-LORIS-ULTRA.py
    ```

2.  **Answer the interactive prompts** exactly as follows to target Server A:
    *   `[?] Attack IP or Domain? (ip/domain):` **domain**
    *   `[?] Enter target domain:` **localhost**
    *   `[?] Enter target port (default 80):` **8443**
    *   `[?] Use HTTPS? (y/n):` **y**
    *   `[?] Number of attack workers...:` **1000**
    *   `[?] Attack duration in seconds...:` **60**
    *   `[?] Use Tor? (y/n):` **n**
    *   `[?] Safe mode...? (y/n):` **n**
    *   `[?] LAUNCH MASSIVE ATTACK? (y/n):` **y**

3.  **Expected Outcome:** The script will report a high number of requests per second (RPS), and you will find that trying to access `https://localhost:8443` in a browser will be very slow or fail completely.

---

## Phase 2: Testing Server B (PQC-Hardened Server)

Here, we run the same tests against Server B to demonstrate its enhanced security.

### Test 2.1: Database Exfiltration Attempt

1.  **Run the script:** Use the same command as before, but targeting Server B's port:
    ```bash
    python attacker/sql_injector.py https://localhost:9443
    ```

2.  **Expected Outcome:** The script will still run, and it will successfully dump data from the database. However, the `message_text` and `encrypted_key` fields will be printed as long strings of random-looking binary data. This demonstrates that even though the database was stolen, the sensitive information remains **unreadable and secure** thanks to our PQC-hybrid encryption.

### Test 2.2: PQC Traffic Analysis & Stress Test

This is a two-part test. We will start capturing network traffic, then run the stress test.

1.  **Find Your Network Interface:**
    ```bash
    tshark -D
    ```
    Note the number of your primary loopback or local network interface.

2.  **Start Traffic Capture:** In a new terminal, start `tshark`. Replace `INTERFACE_NUMBER` with the number from the previous command.
    ```bash
    tshark -i INTERFACE_NUMBER -w attacker/pqc_capture.pcap -f "tcp port 9443"
    ```

3.  **Run the Stress Test:** In another terminal, run the `HULK-LORIS-ULTRA.py` script, answering the prompts to target Server B:
    *   `[?] ... target domain:` **localhost**
    *   `[?] ... target port ...:` **9443**
    *   ... (answer the rest as you did for Server A)

4.  **Stop and Analyze:** After a minute, stop the test script (`Ctrl+C`) and the `tshark` capture (`Ctrl+C`).

5.  **Analyze the Capture File:** Run this command to inspect the TLS handshake:
    ```bash
    tshark -r attacker/pqc_capture.pcap -Y "tls.handshake.type == 1" -V
    ```
    Look for the `supported_groups` extension in the output. The presence of **`secp384r1:kyber768`** proves that the connection was protected by Post-Quantum Cryptography.

This concludes the demonstration. You have shown that Server B protects data both at-rest and in-transit using PQC.
