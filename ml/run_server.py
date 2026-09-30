"""Lance l'API ML en libérant d'abord le port (évite WinError 10048 sous Windows).

Usage (depuis ml/) :
  .venv\\Scripts\\python run_server.py
  .venv\\Scripts\\python run_server.py --port 8000
"""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
import time


def _pids_on_port(port: int) -> list[int]:
    pids: set[int] = set()
    if sys.platform.startswith("win"):
        try:
            out = subprocess.check_output(["netstat", "-ano"], text=True, errors="ignore")
        except Exception:
            return []
        needle = f":{port}"
        for line in out.splitlines():
            if needle not in line:
                continue
            # Connexions LISTENING / ESTABLISHED sur ce port local.
            parts = line.split()
            if len(parts) < 5:
                continue
            local = parts[1] if len(parts) > 1 else ""
            if not local.endswith(f":{port}"):
                continue
            try:
                pid = int(parts[-1])
            except ValueError:
                continue
            if pid > 0:
                pids.add(pid)
    else:
        try:
            out = subprocess.check_output(["lsof", "-t", f"-i:{port}"], text=True, errors="ignore")
            for line in out.splitlines():
                line = line.strip()
                if line.isdigit():
                    pids.add(int(line))
        except Exception:
            pass
    return sorted(pids)


def free_port(port: int) -> None:
    pids = _pids_on_port(port)
    if not pids:
        print(f"[ml] Port {port} libre.")
        return
    for pid in pids:
        try:
            if sys.platform.startswith("win"):
                subprocess.run(["taskkill", "/PID", str(pid), "/F"], check=False, capture_output=True)
            else:
                os.kill(pid, 9)
            print(f"[ml] Processus {pid} sur le port {port} arrêté.")
        except Exception as exc:
            print(f"[ml] Impossible d'arrêter PID {pid}: {exc}")
    time.sleep(1.0)
    leftover = _pids_on_port(port)
    if leftover:
        print(f"[ml] Attention: port encore occupé par {leftover}")
    else:
        print(f"[ml] Port {port} libéré.")


def main() -> None:
    parser = argparse.ArgumentParser(description="MooMoo ML API (uvicorn + free port)")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8000)
    parser.add_argument("--reload", action="store_true")
    args = parser.parse_args()

    free_port(args.port)
    os.environ.setdefault("TF_ENABLE_ONEDNN_OPTS", "0")

    # Import tardif pour que free_port fonctionne même si TF met du temps.
    import uvicorn

    print(f"[ml] uvicorn sur http://{args.host}:{args.port} ...")
    uvicorn.run(
        "main:app",
        host=args.host,
        port=args.port,
        reload=args.reload,
    )


if __name__ == "__main__":
    main()
