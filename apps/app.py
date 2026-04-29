from flask import Flask
import os
import socket

app = Flask(__name__)

@app.route("/")
def hello():
    # This proves the app knows which Pod it is running in
    html = "<h3>Hello Raheem!</h3>" \
           "<b>Hostname:</b> {hostname}<br/>" \
           "<b>Environment:</b> {env}"
    return html.format(hostname=socket.gethostname(), env=os.getenv("ENVIRONMENT", "Production"))

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)