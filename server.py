import os
import sys
import mimetypes
from http.server import HTTPServer, SimpleHTTPRequestHandler

# --- FIX: Explicitly set MIME types ---
# Windows registry often lacks .mjs, causing Python to serve it as text/plain.
mimetypes.add_type('application/javascript', '.js')
mimetypes.add_type('application/javascript', '.mjs')
mimetypes.add_type('application/wasm', '.wasm')

# The path to your published files relative to the csproj
# Note: Ensure you have run 'dotnet publish -c Release' first!
PUBLISH_DIR = os.path.join("buildwasm")

class COOP_COEP_RequestHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        # These headers allow SharedArrayBuffer (Threading) to work
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        # Prevent caching so you see changes immediately
        self.send_header('Cache-Control', 'no-store, must-revalidate')
        SimpleHTTPRequestHandler.end_headers(self)

if __name__ == '__main__':
    # Check if the publish directory exists
    if not os.path.exists(PUBLISH_DIR):
        print(f"Error: Could not find directory: {PUBLISH_DIR}")
        print("Did you forget to run: dotnet publish -c Release ?")
        sys.exit(1)

    # Change the current working directory to the publish folder
    os.chdir(PUBLISH_DIR)

    port = 8000
    print(f"----------------------------------------------------------------")
    print(f" Serving files from: {PUBLISH_DIR}")
    print(f" Headers enabled:    COOP, COEP")
    print(f" MIME Fixed:         .mjs -> application/javascript")
    print(f" Local Address:      http://localhost:{port}")
    print(f"----------------------------------------------------------------")

    httpd = HTTPServer(('localhost', port), COOP_COEP_RequestHandler)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping server...")
        httpd.server_close()