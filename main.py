from setup import status, ag
from socketApp import socketio, app as sock  # allowed?
from httpServer import app as server, gen_noise as noise
from threading import Thread

if __name__ == "__main__":
  Thread(target=noise).start()
  Thread(target=socketio.run, args=(sock,), kwargs={'port': 5001}).start()
  server.run(host='localhost', port=5000, debug=False,
             use_reloader=False)
