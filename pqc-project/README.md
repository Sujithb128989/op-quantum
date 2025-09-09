# PQC Demonstration Suite: Data-in-Transit and Data-at-Rest

## 1. Project Objective

This project provides a hands-on demonstration of Post-Quantum Cryptography (PQC) applied to two critical areas of web security.

## 2. How to Run the Demonstration

**Prerequisite:** You must have a **Windows** machine with **MSYS2** installed. All commands below should be run from the **MSYS2 MINGW64** terminal, starting from the `pqc-project` root directory.

### Phase 1: Environment Check & Setup

**IMPORTANT FIRST STEP: Check your environment**

Before you begin, run the environment diagnostic script. This will check if you have all the necessary tools installed and available in your shell's PATH.

```bash
./doctor.sh
```

If the `doctor.sh` script reports any errors, you must resolve them before proceeding. The most common solution is to run the main setup script and restart your terminal, as described below.

---

### Phase 2: Initial Project Setup

These steps only need to be performed once. **Please perform them in this exact order.**

1.  **Install System Dependencies:** Run the setup script to install all required compilers and tools.
    ```bash
    ./setup_msys2.sh
    ```
    **IMPORTANT:** After this script finishes, you **MUST close and reopen** the MSYS2 terminal before proceeding to the next step. This allows the terminal to recognize the newly installed programs.

2.  **Build C-Libraries and Servers:** Compile the Nginx binaries and the underlying PQC libraries. This will take a significant amount of time.
    ```bash
    (cd server_a && ./build_standard_server.sh)
    (cd server_b && ./build_pqc_server.sh)
    ```
3.  **Set Up Python Environment & Install Libraries:** We will use a virtual environment to avoid conflicts with the system Python.
    ```bash
    /mingw64/bin/python -m venv venv
    source venv/Scripts/activate
    pip install -r app/requirements.txt
    pip install -r attacker/requirements.txt
    ```
4.  **Generate Certificates:** Create the self-signed certificates for both servers.
    ```bash
    ./generate_certs.sh
    ```

---

### Phase 3: Showcase the Secure Application (Server B)
... (rest of the file remains the same) ...
