# Understanding Post-Quantum Cryptography in This Project

This document explains the core cryptographic concepts used in this demonstration. Our project showcases two distinct applications of Post-Quantum Cryptography (PQC) to provide comprehensive data security.

---

## 1. What is Post-Quantum Cryptography (PQC)?

**The Problem:** The security of the internet today relies on public-key cryptography algorithms like RSA and Elliptic Curve Cryptography (ECC). These algorithms are secure because they are based on mathematical problems that are currently too difficult for even the most powerful supercomputers to solve. However, a sufficiently powerful quantum computer, using algorithms like Shor's algorithm, could solve these problems easily, breaking our current encryption standards and rendering most of our secure communication insecure.

**The Solution:** Post-Quantum Cryptography (PQC) refers to a new generation of cryptographic algorithms that are designed to be secure against attacks from both classical and quantum computers. They are built on different mathematical problems (like lattice-based, code-based, or hash-based cryptography) that are believed to be hard for even quantum computers to solve.

The goal of PQC is to create a new public-key infrastructure that can resist the future threat of quantum computing, ensuring long-term data security.

---

## 2. PQC for Data-in-Transit: Securing Network Traffic

The first layer of security in our project is protecting data as it travels between the user and our web server. This is known as protecting **data-in-transit**.

### How We Achieve It:

*   **Technology:** We use TLS (Transport Layer Security), the standard protocol for HTTPS.
*   **PQC Integration:** Our **Server B** is built with a special version of Nginx that uses a PQC-enabled OpenSSL library. This library is powered by `liboqs` from the Open Quantum Safe project.
*   **Mechanism: Hybrid Key Exchange:** When a user connects to Server B, the TLS handshake uses a **hybrid key exchange** mechanism. In our `nginx.conf`, this is set with `ssl_ecdh_curve secp384r1:kyber768;`.
    *   This command tells the server to perform two key exchanges simultaneously: one using a classical algorithm (Elliptic Curve `secp384r1`) and one using a PQC algorithm (`Kyber-768`).
    *   The two resulting keys are combined to create the final encryption key for the session.
*   **Why Hybrid?** This approach provides the best of both worlds. The connection is secure against classical attacks (thanks to ECC) AND future quantum attacks (thanks to Kyber). It also ensures compatibility with the modern cryptographic ecosystem.

**In this project, this layer prevents an attacker who is eavesdropping on the network from reading any of the data being sent to or from Server B.**

---

## 3. PQC for Data-at-Rest: Securing the Database

The second, more advanced layer of security in our project is protecting the data while it is stored in our database. This is known as protecting **data-at-rest**. This is designed to protect us even if an attacker completely bypasses the web server and steals the database file itself.

### How We Achieve It:

PQC algorithms like Kyber are designed for key exchange, not for encrypting large amounts of data directly. Therefore, we use a standard, highly efficient cryptographic construction called a **KEM-DEM scheme** (Key Encapsulation Mechanism + Data Encapsulation Mechanism).

*   **KEM (Key Encapsulation Mechanism):** This is our PQC algorithm, **Kyber**. Its job is to securely establish a shared secret key.
*   **DEM (Data Encapsulation Mechanism):** This is a standard, fast, and secure symmetric cipher, **AES-256-GCM**. Its job is to encrypt and decrypt the actual data.

### The Encryption Process (in `app/pqc_crypto.py`):

When a user on Server B sends a message that needs to be stored securely:

1.  **Generate Symmetric Key:** Our backend application first generates a fresh, random key for the AES-256 cipher.
2.  **Encapsulate the Key:** It then uses the **public key** of our PQC algorithm (Kyber) to "encapsulate" (encrypt) this AES key. This process creates a PQC-secure ciphertext of the AES key.
3.  **Encrypt the Data:** The application uses the (plaintext) AES key to encrypt the user's message.
4.  **Store in Database:** Both the **encrypted AES key** and the **encrypted message** are stored together in the database.

### The Decryption Process:

When the application needs to retrieve and display the message:

1.  **Retrieve from Database:** It fetches the encrypted AES key and the encrypted message.
2.  **Decapsulate the Key:** It uses the **private key** of our PQC algorithm (Kyber) to "decapsulate" (decrypt) the encrypted AES key. This securely recovers the original AES key.
3.  **Decrypt the Data:** The application uses the recovered AES key to decrypt the message ciphertext.

**This scheme ensures that even if an attacker steals the entire database file, they cannot read the messages. They have the encrypted data, but they cannot get the AES keys used to decrypt it without breaking the quantum-resistant PQC algorithm.** This is the core of the data-at-rest protection provided by Server B.
