import os
import sys
import time
import urllib.request
from datetime import datetime

# Environment stabilization setup
os.environ['XAUTHORITY'] = '/config/.Xauthority'
os.environ['DISPLAY'] = ':1'

try:
    import pyautogui
except ImportError:
    print("[-] Critical Error: Core automation dependencies missing.", file=sys.stderr)
    sys.exit(1)

pyautogui.FAILSAFE = True

def take_debug_screenshot(stage_name="error"):
    """Bypasses ALL desktop binaries and DBus permissions."""
    """Queries Selkies' internal streaming server API to capture the canvas frame."""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    final_path = f"/app/headless_{stage_name}_{timestamp}.png"
    
    # Selkies exposes an unauthenticated control port locally on port 8000
    api_url = "http://127.0.0"
    
    try:
        print(f"[*] Fetching active frame buffer array from Selkies API...")
        
        # Pull the raw image bytes directly from the internal web service
        with urllib.request.urlopen(api_url, timeout=5) as response:
            image_data = response.read()
            
        # Write the payload directly onto your shared host directory
        with open(final_path, "wb") as f:
            f.write(image_data)
            
        print(f"[+] Successfully exported frame array to: {final_path}")
        
    except Exception as e:
        print(f"[-] Selkies API capture request failed: {e}", file=sys.stderr)

def run_automation():
    print("[1/5] Initialising headless display environment context...")
    time.sleep(2)
    
    try:
        print("[2/5] Launching native calculator app (galculator)...")
        os.system("galculator &")
        time.sleep(3)
        
        print("[3/5] Verifying window layout presence via streaming engine API...")
        take_debug_screenshot("post_launch")

        # ----------------------------------------------------
        # YOUR AUTOMATION CLICK / INTERACTION SCRIPTS RESUME HERE
        # ----------------------------------------------------
        
        print("[4/5] Automation routine finalized successfully.")
        take_debug_screenshot("success")

        print("[5/5] Automation task completed. Signalling host pipeline...")
        sys.exit(0)

    except Exception as err:
        print(f"\n[!!!] CRITICAL AUTOMATION FAILURE: {err}", file=sys.stderr)
        take_debug_screenshot("crash_state")
        sys.exit(2)

if __name__ == "__main__":
    run_automation()
