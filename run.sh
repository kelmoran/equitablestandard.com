#!/bin/sh
# Start (or restart) the Equitable Standard static site on port 8992.
# Serves this directory's static files (index.html, style.css, script.js) with
# no-cache headers. Stdlib only — no venv needed.
cd "$(dirname "$0")"
mkdir -p logs

PORT=8992
# Kill any existing instance on this port
pkill -9 -f "port $PORT" 2>/dev/null
sleep 1

python3 - "$PORT" <<'PY' 2>&1 | tee logs/server.log
import http.server, socketserver, sys
from datetime import datetime
PORT = int(sys.argv[1])
SERVE_DIR = "."

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=SERVE_DIR, **kwargs)
    def log_message(self, fmt, *args):
        print(f"{datetime.now().isoformat()} - {fmt % args}", flush=True)
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate')
        self.send_header('Pragma', 'no-cache')
        super().end_headers()

socketserver.TCPServer.allow_reuse_address = True
with socketserver.TCPServer(("", PORT), Handler) as httpd:
    print(f"Equitable Standard server on port {PORT}", flush=True)
    httpd.serve_forever()
PY
