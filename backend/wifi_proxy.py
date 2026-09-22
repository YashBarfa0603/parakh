import http.server
import socketserver
import sys
import httpx

class ThreadedHTTPServer(socketserver.ThreadingMixIn, http.server.HTTPServer):
    daemon_threads = True
    allow_reuse_address = True

class ProxyHandler(http.server.BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        sys.stdout.write(f"[{self.log_date_time_string()}] {self.command} {self.path} - {format % args}\n")
        sys.stdout.flush()

    def do_GET(self): self._proxy()
    def do_POST(self): self._proxy()
    def do_PUT(self): self._proxy()
    def do_DELETE(self): self._proxy()
    def do_OPTIONS(self): self._proxy()

    def _proxy(self):
        length = int(self.headers.get('Content-Length', 0))
        data = self.rfile.read(length) if length > 0 else None

        # Filter hop-by-hop headers
        forward_headers = {}
        for k, v in self.headers.items():
            if k.lower() not in ('host', 'content-length', 'transfer-encoding', 'connection'):
                forward_headers[k] = v

        backend_url = f"http://127.0.0.1:8000{self.path}"

        try:
            with httpx.Client(timeout=120.0, follow_redirects=True) as client:
                resp = client.request(
                    method=self.command,
                    url=backend_url,
                    content=data,
                    headers=forward_headers
                )

                self.send_response(resp.status_code)
                for k, v in resp.headers.items():
                    if k.lower() not in ('transfer-encoding', 'connection', 'content-encoding', 'content-length'):
                        self.send_header(k, v)
                self.send_header('Content-Length', str(len(resp.content)))
                self.end_headers()
                self.wfile.write(resp.content)
                self.log_message(f"-> {resp.status_code} ({len(resp.content)} bytes)")
        except Exception as e:
            self.log_message(f"-> Error: {e}")
            self.send_response(502)
            self.end_headers()
            self.wfile.write(f'{{"error": "Proxy Error", "detail": "{e}"}}'.encode())

if __name__ == '__main__':
    with ThreadedHTTPServer(('0.0.0.0', 8080), ProxyHandler) as httpd:
        print("Multithreaded Wi-Fi Proxy running on http://0.0.0.0:8080 -> 127.0.0.1:8000")
        sys.stdout.flush()
        httpd.serve_forever()
