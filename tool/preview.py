#!/usr/bin/env python3
"""Serve the locally compiled Flutter preview. No external Python dependencies."""
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from functools import partial
import argparse
import webbrowser
parser = argparse.ArgumentParser()
parser.add_argument('--port', type=int, default=8080)
parser.add_argument('--no-open', action='store_true')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1] / 'build' / 'web'
if not (root / 'index.html').exists():
    raise SystemExit('Build the preview first: flutter build web --release --no-web-resources-cdn')
server = ThreadingHTTPServer(('127.0.0.1', args.port), partial(SimpleHTTPRequestHandler, directory=str(root)))
url = f'http://localhost:{args.port}'
print(f'Aula preview: {url}\nPress Ctrl+C to stop.')
if not args.no_open:
    webbrowser.open(url)
try:
    server.serve_forever()
except KeyboardInterrupt:
    server.server_close()
