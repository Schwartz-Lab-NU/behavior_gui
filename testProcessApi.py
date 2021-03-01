from flask import Flask
from flask_socketio import SocketIO, emit
import numpy as np


def getRandomItem():
  r = np.random.rand(1)
  if r < .1:
    return None  # indicates currently processing
  elif r < .55:
    return False  # indicates not done
  else:
    return True  # indicates done


def getRandomStatus(rootfilename):
  return [
      [getRandomItem(), getRandomItem(), getRandomItem(), getRandomItem()],
      [getRandomItem()],
      [getRandomItem(), getRandomItem()],
      [getRandomItem(), getRandomItem()]
  ]


app = Flask(__name__)
socketio = SocketIO(app, cors_allowed_origins='*', async_mode='eventlet')


@socketio.on('connect')
def handle_new_connection():
  print('new client registered')


@socketio.on('disconnect')
def handle_closed_connection():
  print('client disconnected')


@socketio.on('get')
def parse_request(request_type, *args):
  print('Requested resource: ' + request_type)

  if request_type == 'processing':
    return {
        'first': args[0],
        'sessions': [{
            'name': f'mouse{i}',  # get the actual rootfile name
            'status': getRandomStatus()} for i in range(args[0], min(args[0] + args[1], 110))]
    }  # suppose 110 is the number of actual sessions in existence

  # if request_type == 'processed':
  #   return {'index': -1, 'session': 'testMouseABC'}




if __name__ == "__main__":
  print('serving on port 5001')
  socketio.run(app, port=5001)
