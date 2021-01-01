from flask import Flask, render_template
from flask_socketio import SocketIO
import json
import testDefs


app = Flask(__name__, template_folder='./')
socketio = SocketIO(app, cors_allows_origins='*')


@app.route('/')
def hello_world():
  return render_template('./testTemplate.html')


@socketio.on('connect')
def handle_new_connection():
  # pass
  print('new client registered')


@socketio.on('get')
def parse_request(request_type):
  print('Requested resource: ' + request_type)

  if request_type == 'allowed':
    print('sending allowed settings dictionary', testDefs.initialStatus)
    return testDefs.initialStatus
    # return 'testString'

  elif request_type == 'current':
    return {k: v['current'] for k, v in testDefs.initialStatus.items()}


@socketio.on('post')
def parse_update(update):
  print('Requested change: ' + str(update))
  # the update is a dictionary of status:value pairs

  # 1) parse the request to make sure the requested value is allowed (this is also done client side, but just to be safe)

  # for k, v in json.loads(update).items():
  for k, v in update.items():
    # 2a) if allowed, perform the update on the rig

    # 2b) update the status structure as necessary
    testDefs.initialStatus[k]['current'] = v
    # an update of one status may affect another
    testDefs.initialStatus['initialization']['current'] = 'initialized'

  # 3) send the new status to all other clients as a 'broadcast' event

  # 4) return the new status to the requesting client
  return {k: v['current'] for k, v in testDefs.initialStatus.items()}


if __name__ == '__main__':
  socketio.run(app)
