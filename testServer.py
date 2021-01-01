from flask import Flask, render_template
from flask_socketio import SocketIO
import json
import testDefs


app = Flask(__name__)
socketio = SocketIO(app, cors_allows_origins='*')


@app.route('/')
def hello_world():
  return 'hello world'  # just a placeholder, for testing


# @socketio.on('connect')
# def handle_new_connection():
#   print('new client registered')


@socketio.on('get')
def parse_request(request_type):
  print('Requested resource: ' + request_type)

  if request_type == 'allowed':
    print('sending allowed settings dictionary')
    return testDefs.initialStatus

  elif request_type == 'current':
    return {k: v['current'] for k, v in testDefs.initialStatus.items()}

  # TODO: this is probably not the most efficient way to do this
  # we probably want to store both response types rather than dynamically create one from the other


@socketio.on('post')
def parse_update(update):
  print('Requested change: ' + str(update))
  # the update is a dictionary of status:value pairs

  # 1) parse the request to make sure the requested value is allowed (this is also done client-side, but just to be safe)

  for k, v in update.items():
    # 2a) if allowed, perform the update on the rig

    # 2b) update the status structure as necessary
    testDefs.initialStatus[k]['current'] = v
    # an update of one status may affect another: below is just an example
    testDefs.initialStatus['initialization']['current'] = 'initialized'

  response = {k: v['current'] for k, v in testDefs.initialStatus.items()}
  # 3) send the new status to all other clients as a 'broadcast' event
  emit('broadcast', response, broadcast=True, include_self=False)

  # 4) return the new status to the requesting client
  return response


if __name__ == '__main__':
  socketio.run(app)
