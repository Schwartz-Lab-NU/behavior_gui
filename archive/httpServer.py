from flask import Flask, Response, request, send_from_directory, render_template

import time
from threading import Thread

import os
import numpy as np

import cv2
import ffmpeg

from flask_cors import CORS, cross_origin
import logging

from behavior_gui.setup import status


app = Flask(__name__)

cors = CORS(app)
app.config['CORS_HEADERS'] = 'Content-Type'
log = logging.getLogger('werkzeug')
log.setLevel(logging.ERROR)  # hides the flask request messages

frame_rate = 15

ran_ffmpeg = False


@app.route('/')
def hello_world():
  return render_template('index.html')  # just a test template


@app.route('/kill')
def kill_server():
  print('doing shutdown')
  status['initialization']('deinitialized')
  time.sleep(3)
  if ran_ffmpeg:
    finish_ffmpeg()
  os._exit(0)
  return


if __name__ == '__main__':
    # ag = AcquisitionGroup(frame_rate=frame_rate, audio_settings=audio_settings)
  ag.start()
  ag.run()
  #Thread(target=socketio.run, args=(appSocket,), kwargs={'port': 5001}).start()
  app.run(host='localhost', port=5000, debug=False,
          use_reloader=False)
