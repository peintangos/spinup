from http.server import HTTPServer, BaseHTTPRequestHandler
import json

PORT = 8000


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        body = json.dumps({"message": "Hello from Python!", "path": self.path})
        self.wfile.write(body.encode())


if __name__ == "__main__":
    server = HTTPServer(("", PORT), Handler)
    print(f"Server running at http://localhost:{PORT}")
    server.serve_forever()
