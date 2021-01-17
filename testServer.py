from flask import Flask, render_template,Response
from flask_socketio import SocketIO, emit
import json
from utils.audio_settings import audio_settings

import time
from threading import Thread
# import testDefs
import behavior_gui.testDefs as testDefs
import AcquisitionGroup

# import os

# import eventlet
# eventlet.monkey_patch()
# from gevent import monkey
# monkey.patch_all()

bgthread = Thread()

app = Flask(__name__)
# app.debug = True #seems to break nidaq
# socketio = SocketIO(app, cors_allows_origins='*', async_mode='eventlet')
socketio = SocketIO(app, cors_allows_origins='*', async_mode='gevent')
ag= AcquisitionGroup.AcquisitionGroup(frame_rate=30,audio_settings=audio_settings)
ag.start(isDisplayed=True)
#ag.run()

@app.route('/')
def hello_world():
  return 'hello world'  # just a placeholder, for testing
  # return render_template('index.html')

@app.route('/video/<int:cam_id>')
def generate_frame(cam_id):
  print('got request for video ', cam_id)
  # if not ag.running:
  #   print('not running')
  #   # Thread(target=ag.run).start()
  #   ag.run()
  #   socketio.start_background_task(ag.run)
  #TODO: if not ag.cameras[cam_id].running, we can't call display()?
  if ag.running:
    return Response(ag.cameras[cam_id].display(), mimetype='multipart/x-mixed-replace; boundary=frame')
  else:
    return Response(status = 503) #service unavailable

@app.route('/audio')
def generate_spectrogram():
  return Response(ag.nidaq.display(), mimetype='multipart/x-mixed-replace; boundary=frame')

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
    #e.g. k = 'initialization', v='initialized' <- gui is trying to turn on the rig
    #testDefs.initialStatus[k]['callback'](v)

    # 2a) if allowed, perform the update on the rig
    if k == 'calibration':
      # threading.Thread(target=doCalibration, args=(v,)).start()
      # socketio.start_background_task(doCalibration, (v,))
      bgthread = Thread(target=doCalibration, args=(v,)).start()
    elif 'display' in k: # e.g. k="audio.display"
      #add/remove client to display list for the particular stream
      #only if we change between no clients displaying vs. any clients displaying will we actually change the display status
      testDefs.initialStatus[k]['current'] = v
    elif k == 'initialization':
      # pass
      if not ag.running:
        ag.run()
        print('exited ag.run')
      else:
        print("it's running")

    # 2b) update the status structure as necessary
    #NOTE: this might not be how we want to handle every status... maybe the update failed
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
  print('emitted done calibration status')


if __name__ == '__main__':
  socketio.run(app) #could set the port here manually like in main.py
  #localhost == 127.0.0.1

  #default port = 5000
  # address: localhost:5000/video/0
