# Data-in-Transit Protection

This document explains how the project demonstrates the protection of **data-in-transit**. This protection is handled by HTTPS, which uses TLS encryption to secure the connection between the client browser and the server.

## Server Configuration Differences

The key difference lies in the TLS configuration of the two servers.

*   **Server A (Standard):** Uses a standard **RSA** certificate. This is a common standard for web security but is considered vulnerable to future attacks from quantum computers.
*   **Server B (PQC-Hardened):** Uses a **hybrid** configuration that combines classical cryptography with Post-Quantum Cryptography (PQC) to protect against both classical and quantum threats.
    *   **Authentication:** The server's certificate is signed with the **Dilithium3** PQC algorithm.
    *   **Key Exchange:** The TLS connection uses a hybrid key exchange method combining **Kyber768** (a PQC algorithm) with a classical one (`secp384r1`).

This hybrid approach ensures the connection is secure against both current and future threats.

## Demonstration Steps

Proof of PQC usage on Server B can be found by inspecting its TLS certificate in a web browser.

1.  Navigate to the website for **Server B** (e.g., `https://<IP_ADDRESS>:9443`).
2.  Bypass the self-signed certificate warning to proceed to the site.
3.  Click the **lock icon** in the browser's address bar.
4.  Select **"Connection is secure"** (or similar text).
5.  Select **"Certificate is valid"** (or navigate through "More Information" to view the certificate).
6.  In the certificate viewer, locate the **"Signature Algorithm"** field.
7.  **Verification:** The algorithm name for Server B will reference the PQC algorithm, such as **`Dilithium3`** or a related OID (Object Identifier). This can be contrasted with the certificate from Server A (`https://<IP_ADDRESS>:8443`), which will show a standard algorithm like RSA.
