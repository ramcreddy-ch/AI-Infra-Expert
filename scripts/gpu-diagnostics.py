import subprocess
import sys
import json

def get_nvidia_smi_json():
    try:
        # Query GPU properties
        cmd = [
            "nvidia-smi",
            "--query-gpu=index,name,driver_version,memory.total,memory.used,utilization.gpu,temperature.gpu,power.draw",
            "--format=json"
        ]
        result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=True)
        return json.loads(result.stdout)
    except FileNotFoundError:
        return {"error": "nvidia-smi executable not found on host."}
    except Exception as e:
        return {"error": f"Failed to execute nvidia-smi: {str(e)}"}

def run_diagnostics():
    print("--- Running Python GPU Diagnostics ---")
    data = get_nvidia_smi_json()
    
    if "error" in data:
        print(f"ERROR: {data['error']}")
        sys.exit(1)
        
    gpus = data.get("nvidia_smi_log", {}).get("gpu", [])
    if not gpus:
        # Check if output is a direct list
        gpus = data.get("gpus", [])
        
    if not gpus:
        print("No GPUs discovered by nvidia-smi query.")
        sys.exit(0)
        
    for gpu in gpus:
        idx = gpu.get("index", "Unknown")
        name = gpu.get("name", "Unknown")
        mem_total = gpu.get("fb_memory_usage", {}).get("total", "Unknown")
        mem_used = gpu.get("fb_memory_usage", {}).get("used", "Unknown")
        util = gpu.get("utilization", {}).get("gpu_util", "Unknown")
        temp = gpu.get("temperature", {}).get("gpu_temp", "Unknown")
        
        print(f"GPU [{idx}]: {name}")
        print(f"  - Memory: {mem_used} / {mem_total}")
        print(f"  - Utilization: {util}")
        print(f"  - Temp: {temp} C")
        print("-" * 30)

if __name__ == "__main__":
    run_diagnostics()
