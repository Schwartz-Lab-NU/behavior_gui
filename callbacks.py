from behavior_gui.setup import ag, status
# from initialStatus import status
from utils import path_operation_utils as pop


def initialization(state):
  if state == 'initialized':
    ag.start()  # need the filepaths here for the temp videos?
    ag.run()
  else:
    ag.stop()


status['initialization'].callback(initialization)


def recording(state):
  if state:
    rootfilename = status['rootfilename'].current
    print(f'rootfilename was: {rootfilename}')
    camera_list = []
    for i in range(ag.nCameras):
      camera_list.append(ag.cameras[i].device_serial_number)
    filepaths = pop.reformat_filepath('', rootfilename, camera_list)
    # still need the filepaths he for the temp videos?
    ag.start(filepaths=filepaths)

    ag.run()
    status['initialization'].immutable()
    status['calibration'].immutable()
  else:
    ag.stop()
    status['initialization'].mutable()
    status['calibration'].mutable()


status['recording'].callback(recording)


def rootfilename(state):
  print(f'attempted to set rootfilename to {state}')


status['rootfilename'].callback(rootfilename)


def calibration(state):
  if state == 'calibrating':
    status['initialization'].immutable()
    status['calibration'].immutable()
  else:
    status['initialization'].mutable()
    status['calibration'].mutable()


status['calibration'].callback(calibration)


def spectrogram(state):
  print(f'applying new status from state: {state}')
  ag.nidaq.parse_settings(status['spectrogram'].current)
  # TODO: trying to update _nx or _nfft will cause an error
  # that means we can only update log scaling and noise correction


status['spectrogram'].callback(spectrogram)
