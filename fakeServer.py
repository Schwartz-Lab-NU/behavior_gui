from flask import Flask, Response, request
from flask_socketio import SocketIO, emit

import time
from threading import Thread
import testDefs

import os
from PIL import Image
import numpy as np
from io import BytesIO

import cv2

appMain = Flask(__name__)
appSocket = Flask(__name__)

socketio = SocketIO(appSocket, cors_allowed_origins='*', async_mode='eventlet')


@appMain.route('/')
def hello_world():
  return 'hello world'


@appMain.route('/kill')
def kill_server():
  print('doing shutdown')
  os._exit(0)
  return 'Server is shutting down'


def rgba(nparray):
  # nparray = np.left_shift(nparray, 24)
  # nparray += np.right_shift(nparray, 8) + np.right_shift(nparray, 16)
  # nparray += 255  # full alpha
  # full alpha mask
  nparray += np.left_shift(nparray, 16) + \
      np.left_shift(nparray, 8) + 4278190080
  return nparray.tobytes()


def make_frame(imarray, i):
  imarray[:] = 0
  cv2.putText(imarray, f'Frame {i}', (100, 100),
              cv2.FONT_HERSHEY_SIMPLEX, 3, (255, 255, 255), 3, 2)
  imarray[:, :, 3] = 255


def gen_noise():
  i = 0
  x = np.linspace(start=0, stop=255, num=256)
  # xx = x + 1j * x[:, np.newaxis]
  # frame_bytes = BytesIO()
  # imarray = [
  #     np.zeros((1280, 1024), dtype=np.uint32),
  #     np.ones((1280, 1024), dtype=np.uint32) * 128
  # ]

  im_array = np.ones((1024, 1280, 4), dtype=np.uint8) * 255

  last_time = time.time()

  while testDefs.initialStatus['initialization']['current'] == 'initialized':
    # while i == 0:

    # 1,0,2 'c' is close... but flipped
    # imarray2 = np.transpose(make_frame(i), (1, 0, 2)).tobytes()
    # imarray2 = np.transpose(make_frame(i), (2, 0, 1)).tobytes('F')
    make_frame(im_array, i)

    if i % 20 == 0:
      print(f'Made frame {i}')

    time.sleep(max(1/15 - (time.time() - last_time), 0))
    last_time = time.time()
    # yield(b'--frame\r\nContent-Type: image/jpeg\r\n\r\n' + frame_bytes.getvalue() + b'\r\n')
    yield(im_array.tobytes())
    # yield(rgba(imarray2.copy()))
    # i = (i + 10) % 256
    i += 1


@appMain.route('/video/<int:cam_id>')
def generate_frame(cam_id):
  print('got request for video ', cam_id,)
  if testDefs.initialStatus['initialization']['current'] == 'initialized':
    return Response(gen_noise(), mimetype='multipart/x-mixed-replace')
    # return Response(gen_noise(), mimetype='multipart/x-mixed-replace; boundary=frame')
  else:
    return Response(status=503)  # service unavailable


@socketio.on('connect')
def handle_new_connection():
  # maintain some record of which clients have the display on
  emit('broadcast', {k: v['current']
                     for k, v in testDefs.initialStatus.items()})
  print('new client registered')


@socketio.on('disconnect')
def handle_closed_connection():
  # remove the client from the display list
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
    # e.g. k = 'initialization', v='initialized' <- gui is trying to turn on the rig
    # testDefs.initialStatus[k]['callback'](v)

    # 2a) if allowed, perform the update on the rig
    if k == 'calibration':
      # threading.Thread(target=doCalibration, args=(v,)).start()
      # socketio.start_background_task(doCalibration, (v,))

      # bgthread = Thread(target=doCalibration, args=(v,)).start() TODO: THIS WILL NOT WORK
      doCalibration(v)
      testDefs.initialStatus['calibration']['current'] = 'calibrated'
    elif 'display' in k:  # e.g. k="audio.display"
      # add/remove client to display list for the particular stream
      # only if we change between no clients displaying vs. any clients displaying will we actually change the display status
      testDefs.initialStatus[k]['current'] = v
    else:
      # 2b) update the status structure as necessary
      # NOTE: this might not be how we want to handle every status... maybe the update failed
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


if __name__ == '__main__':
  testDefs.initialStatus['initialization']['current'] = 'initialized'

  Thread(target=socketio.run, args=(appSocket,), kwargs={'port': 5001}).start()
  appMain.run(host='localhost', port=5000, debug=False, use_reloader=False)

  # im_array = np.ones((1280, 1024, 4), dtype=np.uint8) * 255
  # make_frame(im_array, 0)

  # cv2.imshow(f'Frame 0', im_array)
  # cv2.waitKey(0)
