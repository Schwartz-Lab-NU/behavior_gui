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


def getRandomStatus():
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

  if request_type == 'processing categories':
    return {
        'headers': ['session', 'calibration', 'deepsqueak', 'deeplabcut', 'migration'],
        'info': [
            [{'name': 'Session name',
              'description': 'Set by the root file name during the recording', 'icon': None}],
            [
                {'name': 'Configuration file',
                 'description': 'Copies the configuration file to the session directory', 'icon': 59181},
                {'name': 'Undistortion',
                    'description': 'Uses the most recent calibration to correct for lens distortion', 'icon': 58868},
                {'name': 'Coordinate extraction',
                    'description': 'Uses the arena-mounted markers to detect the location of the aerna', 'icon': 58950},
                {'name': '3D alignment', 'description': 'Uses the extrinsic calibration data to extract the position of the cameras relative to the arena', 'icon': 59735}
            ],
            [{'name': 'DeepSqueak', 'description': 'Parses the microphone data for squeaks',
              'icon': 59288}],
            [
                {'name': 'DeepLabCut', 'description': 'Extracts 2D pose estimates of mice in the arena',
                 'icon': 59813},
                {'name': '3D pose estimation',
                    'description': 'Transforms the DeepLabCut results into 3D coordinates using the calibration data', 'icon': 60097}
            ],
            [
                {'name': 'Upload', 'description': 'Uploads the data to the Schwartz Lab server',
                 'icon': 58981},
                {'name': 'HDD', 'description': 'Transfers the data to long-term storage on this computer', 'icon': 59809}
            ]
        ]
    }


if __name__ == "__main__":
  print('serving on port 5001')
  socketio.run(app, port=5001)
