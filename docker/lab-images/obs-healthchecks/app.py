from http.server import HTTPServer, BaseHTTPRequestHandler
import json, time

start_time = time.time()

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-Type','application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"status":"ok","uptime":int(time.time()-start_time)}).encode())
        elif self.path == '/ready':
            self.send_response(200)
            self.send_header('Content-Type','application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"status":"ready"}).encode())
        else:
            self.send_response(404)
            self.end_headers()
    def log_message(self, *args): pass

HTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
