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
  status[f'camera {i}'].current['width'](ag.cameras[i].width)
  status[f'camera {i}'].current['height'](ag.cameras[i].height)
  status[f'camera {i}'].current['serial number'](
      ag.cameras[i].device_serial_number)
  status[f'camera {i}'].current['port'](ag.cameras[i].address[1])

status['spectrogram'].current['port'](ag.nidaq.address[1])
