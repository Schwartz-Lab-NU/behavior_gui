# from gevent import monkey
# monkey.patch_all()

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
# from gevent.pywsgi import WSGIServer

appMain = Flask(__name__)
appSocket = Flask(__name__)
# app.debug = True #seems to break nidaq

# socketio = SocketIO(app, cors_allowed_origins='*', async_mode='gevent')
socketio = SocketIO(appSocket, cors_allowed_origins='*', async_mode='eventlet')
ag= AcquisitionGroup.AcquisitionGroup(frame_rate=30,audio_settings=audio_settings)
# ag.start(isDisplayed=False)
#ag.run()

@appMain.route('/')
def hello_world():
  return 'hello world'  # just a placeholder, for testing
  # return render_template('index.html')

@appMain.route('/video/<int:cam_id>')
def generate_frame(cam_id):
  print('got request for video ', cam_id, 'run status: ', ag.cameras[cam_id].running, ag.running)
  #NOTE: camera.running is true after ag.start(), ag.running is true after ag.run()
  if ag.cameras[cam_id].data is None:
    ag.cameras[cam_id].data = True #TODO: this is kind of weird, maybe add a new setter

  if ag.running:
    return Response(ag.cameras[cam_id].display(), mimetype='multipart/x-mixed-replace; boundary=frame')
  else:
    return Response(status = 503) #service unavailable

@appMain.route('/audio')
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

      # bgthread = Thread(target=doCalibration, args=(v,)).start() TODO: THIS WILL NOT WORK
      doCalibration(v)
      testDefs.initialStatus['calibration']['current'] = 'calibrated'
    elif 'display' in k: # e.g. k="audio.display"
      #add/remove client to display list for the particular stream
      #only if we change between no clients displaying vs. any clients displaying will we actually change the display status
      testDefs.initialStatus[k]['current'] = v
    elif k == 'initialization': #TODO: actually parse request, right now just toggling
      # pass
      if not ag.running:
        ag.stop() #shouldn't be needed
        ag.start()
        ag.run()
        print('exited ag.run')
        testDefs.initialStatus[k]['current'] = 'initialized'
      else:
        ag.stop()
        print("was running")
        testDefs.initialStatus[k]['current'] = 'deinitialized'
    else:
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
  # print('emitting done calibration status')
  # socketio.emit('message', 'done calibration')
  # socketio.emit('broadcast', {k: v['current']
  #                             for k, v in testDefs.initialStatus.items()})
  # print('emitted done calibration status')


if __name__ == '__main__':
  Thread(target=socketio.run, args=(appSocket,), kwargs={'port':5001}).start()
  # socketio.run(appSocket, port=5001) #could set the port here manually like in main.py

  appMain.run(host='localhost', port=5000, debug=False, use_reloader=False)

  #localhost == 127.0.0.1

  #default port = 5000
  # address: localhost:5000/video/0
