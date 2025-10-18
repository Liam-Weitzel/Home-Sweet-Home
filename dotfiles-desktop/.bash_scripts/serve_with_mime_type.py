import http.server
import socketserver
from urllib.parse import urlparse, parse_qs

PORT = 8000
DIRECTORY = "/tmp"

class QueryMIMEHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        self.custom_mime = None
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def do_GET(self):
        parsed_url = urlparse(self.path)
        qs = parse_qs(parsed_url.query)
        self.custom_mime = qs.get('mime', [None])[0]
        self.path = parsed_url.path
        print(f"Serving file: {self.path} with mime: {self.custom_mime}")
        super().do_GET()

    def guess_type(self, path):
        if self.custom_mime:
            return self.custom_mime
        return "text/html"

    def end_headers(self):
        # Force inline display for all files
        self.send_header('Content-Disposition', 'inline')
        super().end_headers()

handler = QueryMIMEHandler

with socketserver.TCPServer(("", PORT), handler) as httpd:
    print(f"✅ Serving directory {DIRECTORY} on http://localhost:{PORT}")
    httpd.serve_forever()
