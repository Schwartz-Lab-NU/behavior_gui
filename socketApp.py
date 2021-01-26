from flask import Flask
from flask_socketio import SocketIO, emit

from setup import status, ag
from httpServer import bgthread

app = Flask(__name__)
socketio = SocketIO(app, cors_allowed_origins='*', async_mode='eventlet')


@socketio.on('connect')
def handle_new_connection():
  # maintain some record of which clients have the display on
  emit('broadcast', {k: {f: v for f, v in o.items() if (
      (f == 'current') or (f == 'mutable'))} for k, o in status.items()})
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
    return status

  elif request_type == 'current':
    return {k: {f: v for f, v in o.items() if ((f == 'current') or (f == 'mutable'))} for k, o in status.items()}

  # TODO: this is probably not the most efficient way to do this
  # we probably want to store both response types rather than dynamically create one from the other


@ socketio.on('post')
def parse_update(update):
  print('Requested change: ' + str(update))
  # the update is a dictionary of status:value pairs

  # 1) parse the request to ensure the requested value(s) allowed
  # NOTE: consider illegal combinations of values...

  for k, v in update.items(): #k = 'video0displaying', v = True ## (if 'displaying' in k:) (if 0 in k:) ag.cameras[0].displaying = True
    # e.g. k = 'initialization', v='initialized' <- gui is trying to turn on the rig
    # testDefs.initialStatus[k]['callback'](v)

    # 2a) if allowed, perform the update on the rig
    if k == 'calibration':
      # threading.Thread(target=doCalibration, args=(v,)).start()
      # socketio.start_background_task(doCalibration, (v,))

      # bgthread = Thread(target=doCalibration, args=(v,)).start() TODO: THIS WILL NOT WORK
      # doCalibration(v)
      status['calibration']['current'] = 'calibrated'
    elif 'display' in k:  # e.g. k="audio.display"
      # add/remove client to display list for the particular stream
      # only if we change between no clients displaying vs. any clients displaying will we actually change the display status
      status[k]['current'] = v
    elif k == 'initialization':  # TODO: actually parse request, right now just toggling
      # pass
      if not ag.running:
        ag.stop()  # shouldn't be needed
        ag.start()
        ag.run()
        print('exited ag.run')
        status[k]['current'] = 'initialized'
        bgthread.start()
      else:
        ag.stop()
        print("was running")
        status[k]['current'] = 'deinitialized'
    else:
      # 2b) update the status structure as necessary
      # NOTE: this might not be how we want to handle every status... maybe the update failed
      status[k]['current'] = v

    # an update of one status may affect another: below is just an example
    # testDefs.initialStatus['initialization']['current'] = 'initialized'

  response = {k: {f: v for f, v in o.items() if ((f == 'current') or (f == 'mutable'))}
              for k, o in status.items()}

  # 3) optional: send a string message to all clients that gets displayed on the gui
  emit('message',
       'Requested change: ' + str(update), broadcast=True)

  # 4) send the new status to all other clients as a 'broadcast' event
  emit('broadcast', response, broadcast=True, include_self=False)

  # 5) return the new status to the requesting client
  print('returning status change')
  return response
