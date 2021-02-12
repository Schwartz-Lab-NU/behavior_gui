from AcquisitionGroup import AcquisitionGroup
from RigStatus import RigStatus
# from utils.audio_settings import audio_settings
from behavior_gui.initialStatus import initialStatus

global status
global ag

global printToGUI  # TODO: should be defined in socketApp.py??
# will look something like: socketio.emit("message", f"message content string")

global annotationsToGUI  # TODO: should be defined in socketApp.py??
# will look something like socketio.emit("annotation", {"streamId":0, "data": [ {"rectangle":[(p0x, p0y), ..., (p3x, p3y)]}, ... ]})

# class FakeAcqGroup:
#   def __init__(self):
#     self.running = False

#   def stop(self):
#     self.running = False

#   def start(self):
#     pass

#   def run(self):
#     self.running = True


status = RigStatus(initialStatus)
ag = AcquisitionGroup(status)

# TODO: do this better
for i in range(ag.nCameras):
  thisCamera = status[f'camera {i}'].current

  thisCamera['width'].mutable()
  thisCamera['height'].mutable()
  thisCamera['serial number'].mutable()
  thisCamera['port'].mutable()

  thisCamera['width'](ag.cameras[i].width)
  thisCamera['height'](ag.cameras[i].height)
  thisCamera['serial number'](
      int(ag.cameras[i].device_serial_number))
  thisCamera['port'](ag.cameras[i].address[1])

  thisCamera['width'].immutable()
  thisCamera['height'].immutable()
  thisCamera['serial number'].immutable()
  thisCamera['port'].immutable()

status['spectrogram'].current['port'].mutable()
status['spectrogram'].current['port'](ag.nidaq.address[1])
status['spectrogram'].current['port'].immutable()
