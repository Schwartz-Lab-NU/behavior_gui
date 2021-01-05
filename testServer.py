from flask import Flask, render_template
from flask_socketio import SocketIO, emit
import json
import testDefs
import time
from threading import Thread

import eventlet
eventlet.monkey_patch()

bgthread = Thread()

app = Flask(__name__)
socketio = SocketIO(app, cors_allows_origins='*', async_mode='eventlet')


@app.route('/')
def hello_world():
  return 'hello world'  # just a placeholder, for testing


@socketio.on('connect')
def handle_new_connection():
  #maintain some record of which clients have the display on
  emit('broadcast', {k: v['current']
                     for k, v in testDefs.initialStatus.items()})
  print('new client registered')

@socketio.on('disconnect')
def handle_closed_connection():
  #remove the client from the display list
  pass


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

  # 1) parse the request to ensure the requested value(s) allowed
  # NOTE: consider illegal combinations of values...

  for k, v in update.items():
    # 2a) if allowed, perform the update on the rig
    if k == 'calibration':
      # threading.Thread(target=doCalibration, args=(v,)).start()
      # socketio.start_background_task(doCalibration, (v,))
      bgthread = Thread(target=doCalibration, args=(v,)).start()
    elif 'display' in k:
      #add/remove client to display list for the particular stream
      #only if we change between no clients displaying vs. any clients displaying will we actually change the display status
      pass

    # 2b) update the status structure as necessary
    testDefs.initialStatus[k]['current'] = v

    # an update of one status may affect another: below is just an example
    # testDefs.initialStatus['initialization']['current'] = 'initialized'

  response = {k: v['current'] for k, v in testDefs.initialStatus.items()}

  # 3) optional: send a string message to all clients that gets displayed on the gui
  emit('message',
       'Requested change: ' + str(update), broadcast=True)

  # 4) send the new status to all other clients as a 'broadcast' event
  emit('broadcast', response, broadcast=True, include_self=False)

  # 5) return the new status to the requesting client
  print('returning status change')
  return response


def doCalibration(calibration_type):  # pretend to perform the calibration
  time.sleep(3)
  testDefs.initialStatus['calibration']['current'] = 'calibrated'
  print('emitting done calibration status')
  socketio.emit('message', 'done calibration')
  socketio.emit('broadcast', {k: v['current']
                              for k, v in testDefs.initialStatus.items()})


if __name__ == '__main__':
  socketio.run(app)
