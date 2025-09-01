import oqs
import os
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

# This class encapsulates the PQC-hybrid encryption logic (KEM-DEM scheme).
# KEM: Kyber768 for quantum-resistant key encapsulation.
# DEM: AES-256-GCM for efficient and secure data encapsulation.

class PQCrypto:
    def __init__(self):
        """
        Initializes the cryptographic module.
        - Sets up the PQC Key Encapsulation Mechanism (KEM).
        - Generates a long-term keypair for the server. In a real application,
          this private key would be stored securely and loaded, not generated
          on each run. For this demo, we generate it once per server instance.
        """
        self._kem = oqs.KeyEncapsulation("Kyber768")
        self.public_key = self._kem.generate_keypair()
        # Note: self._kem retains the private key internally after keypair generation.
        print("PQC Crypto module initialized with Kyber768.")

    def encrypt(self, plaintext: bytes) -> tuple[bytes, bytes]:
        """
        Encrypts plaintext data using the standard KEM-DEM scheme.

        Args:
            plaintext: The raw data to encrypt.

        Returns:
            A tuple containing:
            - The encapsulated secret (ciphertext from the KEM).
            - The encrypted data (ciphertext from the DEM).
        """
        if not isinstance(plaintext, bytes):
            raise TypeError("Plaintext must be bytes.")

        # 1. KEM: Generate an encapsulated secret and a shared secret (for the DEM).
        # The shared secret will be used as the symmetric key.
        encapsulated_secret, shared_secret = self._kem.encap_secret(self.public_key)

        # Kyber768 produces a 32-byte shared secret, perfect for AES-256.
        aesgcm = AESGCM(shared_secret)

        # We need a nonce (Number used once) for AES-GCM. It must be unique
        # for each encryption with the same key. 12 bytes is standard.
        nonce = os.urandom(12)

        # 2. DEM: Encrypt the actual data with AES-256-GCM using the shared secret.
        # We prepend the nonce to the ciphertext; we'll need it for decryption.
        encrypted_data = nonce + aesgcm.encrypt(nonce, plaintext, None)

        return encapsulated_secret, encrypted_data

    def decrypt(self, encapsulated_secret: bytes, encrypted_data: bytes) -> bytes:
        """
        Decrypts a ciphertext using the standard KEM-DEM scheme.

        Args:
            encapsulated_secret: The PQC-generated ciphertext containing the secret.
            encrypted_data: The AES-encrypted data, prepended with the nonce.

        Returns:
            The original plaintext data as bytes.
        """
        if not isinstance(encapsulated_secret, bytes) or not isinstance(encrypted_data, bytes):
            raise TypeError("Inputs must be bytes.")

        # 1. KEM: Decapsulate the secret to get the same shared secret (AES key).
        # The private key is stored in the self._kem object.
        shared_secret = self._kem.decap_secret(encapsulated_secret)

        # 2. DEM: Decrypt the data using the recovered shared secret.
        # Extract the nonce from the beginning of the ciphertext blob.
        nonce = encrypted_data[:12]
        ciphertext = encrypted_data[12:]

        aesgcm = AESGCM(shared_secret)
        plaintext = aesgcm.decrypt(nonce, ciphertext, None)

        return plaintext

# Example Usage (for testing purposes)
if __name__ == '__main__':
    print("--- Running PQC Crypto Module Self-Test ---")

    # 1. Initialize the crypto system for a "server"
    server_crypto = PQCrypto()

    # 2. A "client" wants to encrypt data for the server.
    original_data = b"This is a top secret message."
    print(f"Original data: {original_data.decode()}")

    # 3. The client uses the server's public key to encrypt.
    # (In our app, the server does this for data it's storing for itself)
    encapsulated_secret, encrypted_data = server_crypto.encrypt(original_data)

    print(f"\nEncapsulated Secret (first 16 bytes): {encapsulated_secret[:16].hex()}...")
    print(f"Encrypted Data (first 16 bytes): {encrypted_data[:16].hex()}...")

    # 4. The server receives the data and uses its private key to decrypt.
    decrypted_data = server_crypto.decrypt(encapsulated_secret, encrypted_data)
    print(f"\nDecrypted data: {decrypted_data.decode()}")

    # 5. Verify correctness
    assert original_data == decrypted_data
    print("\n--- Self-Test PASSED: Original and decrypted data match. ---")
