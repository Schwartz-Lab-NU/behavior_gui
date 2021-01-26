from setup import status, ag
from socketApp import socketio, app as sock
from httpServer import app as server
from threading import Thread

if __name__ == "__main__":
  Thread(target=socketio.run, args=(sock,), kwargs={'port': 5001}).start()
  server.run(host='localhost', port=5000, debug=False,
             use_reloader=False)
