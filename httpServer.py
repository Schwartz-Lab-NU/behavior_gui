from flask import Flask, Response, request, send_from_directory, render_template

import time
from threading import Thread

import os
import numpy as np

import cv2
import ffmpeg

from flask_cors import CORS, cross_origin
import logging

from setup import status, ag

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


def make_frame(imarray, i):
  imarray[:] = 0
  cv2.putText(imarray, f'Frame {i}', (100, 100),
              cv2.FONT_HERSHEY_SIMPLEX, 3, (255, 255, 255), 3, 2)


def do_ffmpeg(imarray):
  split_time = 1.0  # in seconds, duration of each file
  # NOTE: tried split_time = 0.25, 0.5. Seems like video gets choppier and latency worsens
  # probably due to needing to fetch more files
  # optimum seems to be near 1
  # stream starts at a ~4sec delay
  # but tends to catch up to a little over 1sec delay

  file = (ffmpeg
          .input('pipe:', format='rawvideo', pix_fmt='gray', s='1280x1024', framerate=frame_rate)
          .output('test_stream/stream.m3u8',
                  format='hls', hls_time=split_time,
                  hls_playlist_type='event', hls_flags='omit_endlist',
                  g=int(frame_rate*split_time), sc_threshold=0, vcodec='h264',
                  tune='zerolatency', preset='ultrafast')
          .overwrite_output()
          .run_async(pipe_stdin=True)
          # .global_args('-loglevel', 'error')
          # .run_async(pipe_stdin=True, quiet=True)  # bug~need low logs if quiet
          )

  ran_ffmpeg = True

  while status['initialization']['current'] == 'initialized':
    file.stdin.write(imarray.tobytes())
    yield
  file.stdin.close()
  file.wait()


def finish_ffmpeg():
  # append `#EXT-X-ENDLIST` to end of file
  with open('test_stream/stream.m3u8', 'a') as fobj:
    fobj.write('#EXT-X-ENDLIST')

  ffmpeg \
      .input('test_stream/stream.m3u8') \
      .output('test_stream/final.mp4', vcodec='copy') \
      .run()


def gen_fake_frames():
  print('creating fake frames')
  i = 0
  im_array = np.ones((1024, 1280), dtype=np.uint8) * 255

  last_time = time.time()
  fhandle = do_ffmpeg(im_array)

  while status['initialization']['current'] == 'initialized':
    make_frame(im_array, i)

    next(fhandle, None)

    if i % 60 == 0:
      print(f'Wrote frame {i} ({i / frame_rate} seconds elapsed)')

    time.sleep(max(1/frame_rate - (time.time() - last_time), 0))
    last_time = time.time()

    i += 1

  next(fhandle, None)  # be sure to close the handle


bgthread = Thread(target=gen_fake_frames)


@app.after_request
def add_header(response):
  # decorate header for hls
  # TODO: can we apply the after_request decorator only to /video routes??? as opposed to this if statement
  # TODO: check which of these are really important
  if 'video' in request.path:
    response.headers['X-UA-Compatible'] = 'IE=Edge,chrome=1'
    response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = '0'

  # TODO: this is a duplicate of flask_cors??
  response.headers['Access-Control-Allow-Origin'] = '*'

  return response


@app.route('/video', defaults={'cam_id': 0})
@app.route('/video/<int:cam_id>/', defaults={'file_name': 'stream.m3u8'})
@app.route('/video/<int:cam_id>/<string:file_name>')
@cross_origin()
def stream(cam_id, file_name):
  # print('requested file: ', file_name)
  # if 'm3u8' not in file_name:
  #   print('requested file: ', file_name)
  vid_dir = './test_stream'  # would depend on cam_id
  # NOTE: the hls protocol dictates that the client will first request the .m3u8 file, then additional files as needed
  return send_from_directory(directory=vid_dir, filename=file_name)


# if __name__ == '__main__':
#   testDefs.initialStatus['initialization']['current'] = 'initialized'

#   # Thread(target=gen_noise).start()
#   # Thread(target=socketio.run, args=(appSocket,), kwargs={'port': 5001}).start()
#   app.run(host='localhost', port=5000, debug=False,
#           use_reloader=False)
