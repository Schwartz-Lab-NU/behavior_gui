from flask import Flask
from flask_socketio import SocketIO, emit

from setup import status, ag
from httpServer import bgthread

app = Flask(__name__)
socketio = SocketIO(app, cors_allowed_origins='*', async_mode='eventlet')


@socketio.on('connect')
def handle_new_connection():
  # maintain some record of which clients have the display on
  emit('broadcast', status.update)
  print('new client registered')


@ socketio.on('disconnect')
def handle_closed_connection():
  # remove the client from the display list
  pass


@ socketio.on('get')
def parse_request(request_type):
  print('Requested resource: ' + request_type)

  if request_type == 'allowed':
    print('sending allowed settings dictionary')
    return status.allowed

  elif request_type == 'current':
    return status.update

  # TODO: this is probably not the most efficient way to do this
  # we probably want to store both response types rather than dynamically create one from the other


@ socketio.on('post')
def parse_update(update):
  print('Requested change: ' + str(update))
  # the update is a dictionary of status:value pairs

  for k, v in update.items():
    status[k](v)

  # optional: send a string message to all clients that gets displayed on the gui
  emit('message',
       'Requested change: ' + str(update), broadcast=True)

  # send the new status to all other clients as a 'broadcast' event
  emit('broadcast', status.update, broadcast=True, include_self=False)

  # return the new status to the requesting client
  print('returning status change')
  return status.update
