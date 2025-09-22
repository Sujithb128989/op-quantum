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
        # Per expert advice, dynamically discover the supported KEM algorithm name
        enabled_kems = oqs.get_enabled_kem_mechanisms()
        if "ML-KEM-768" in enabled_kems:
            self.alg_name = "ML-KEM-768"
        elif "Kyber768" in enabled_kems:
            self.alg_name = "Kyber768"
        else:
            raise RuntimeError(f"Neither ML-KEM-768 nor Kyber768 are enabled in this build of liboqs. Enabled KEMs: {enabled_kems}")

        self._kem = oqs.KeyEncapsulation(self.alg_name)
        self.public_key = self._kem.generate_keypair()
        # Note: self._kem retains the private key internally after keypair generation.
        print(f"PQC Crypto module initialized with {self.alg_name}.")

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
        # Per liboqs-python examples, we create a new, "clean" KEM instance
        # for encapsulation, which does not hold a private key.
        with oqs.KeyEncapsulation(self.alg_name) as kem_encap:
            encapsulated_secret, shared_secret = kem_encap.encap_secret(self.public_key)

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

    # 1. Initialize the crypto system for a "server" (Alice)
    server_crypto = PQCrypto()
    alice_public_key = server_crypto.public_key
    print(f"Alice's KEM: {server_crypto.alg_name}")

    # 2. Simulate a "client" (Bob) encapsulating a secret with Alice's public key.
    #    Bob only needs Alice's public key.
    print("\nBob is encapsulating a secret with Alice's public key...")
    with oqs.KeyEncapsulation(server_crypto.alg_name) as bob_kem:
        encapsulated_secret, shared_secret_bob = bob_kem.encap_secret(alice_public_key)

    print(f"Bob's encapsulated secret (first 16 bytes): {encapsulated_secret[:16].hex()}...")
    print(f"Bob's shared secret (first 16 bytes): {shared_secret_bob[:16].hex()}...")

    # 3. Alice receives the encapsulated secret and uses her private key to
    #    derive the same shared secret.
    print("\nAlice is decapsulating the secret with her private key...")
    shared_secret_alice = server_crypto._kem.decap_secret(encapsulated_secret)
    print(f"Alice's shared secret (first 16 bytes): {shared_secret_alice[:16].hex()}...")

    # 4. Verify correctness of the KEM
    assert shared_secret_alice == shared_secret_bob
    print("\n--- KEM Self-Test PASSED: Alice's and Bob's shared secrets match. ---")

    # 5. Test the full encrypt/decrypt cycle from the class
    print("\n--- Testing full KEM-DEM encrypt/decrypt cycle ---")
    original_data = b"This is a top secret message for the full cycle test."
    print(f"Original data: {original_data.decode()}")
    encapsulated, encrypted = server_crypto.encrypt(original_data)
    decrypted = server_crypto.decrypt(encapsulated, encrypted)
    print(f"Decrypted data: {decrypted.decode()}")
    assert original_data == decrypted
    print("--- Full cycle test PASSED. ---")
