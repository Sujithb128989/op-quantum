# How to Demonstrate Data-in-Transit Protection

You asked an excellent question about how this project demonstrates the protection of **data-in-transit**. While the "data-at-rest" protection is easy to see in the database, the data-in-transit protection is more conceptual but just as important.

It is all handled by **HTTPS**, which uses TLS encryption to secure the connection between your browser and the server.

## The Difference Between Server A and Server B

*   **Server A (Standard):** Uses a standard **RSA** certificate. This is the current standard for web security but is vulnerable to future quantum computer attacks.
*   **Server B (PQC-Hardened):** Uses a special **hybrid** configuration that combines classical cryptography with Post-Quantum Cryptography (PQC) to protect against all known threats.
    *   **Authentication:** The server's certificate is signed with the **Dilithium3** PQC algorithm.
    *   **Key Exchange:** The TLS connection itself uses a hybrid key exchange method combining **Kyber768** (a PQC algorithm) with a classical one (`secp384r1`).

This hybrid approach ensures that the connection is secure against both today's computers and tomorrow's quantum computers.

## How to Demonstrate This to an Audience

You can prove that Server B is using PQC by inspecting its certificate directly in your web browser. Here are the steps:

1.  Using Google Chrome or Firefox, navigate to the website for **Server B**. The URL will be something like `https://<YOUR_IP>:9443`.
2.  You will likely see a warning about a self-signed certificate. This is expected. Proceed to the website.
3.  Click the **lock icon** in the address bar.
4.  In the menu that appears, click on **"Connection is secure"** (or similar wording).
5.  Then, click on **"Certificate is valid"** (or "More Information" and then "View Certificate").
6.  This will open the certificate viewer. Look for a field named **"Signature Algorithm"**.
7.  For Server B, you should see an algorithm name that references the PQC algorithm, such as **`Dilithium3`** or a related OID (Object Identifier).

By showing this to your audience, you are providing concrete proof that the server is not using standard encryption but is instead using a next-generation, post-quantum cryptographic algorithm to protect all data that travels between the server and the user. You can then compare this to the certificate from Server A (`https://<YOUR_IP>:8443`), which will show a standard algorithm like RSA.
