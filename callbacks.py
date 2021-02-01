from setup import ag, status
# from initialStatus import status


def initialization(state):
  if state == 'initialized':
    ag.start()
    ag.run()
  else:
    ag.stop()


status['initialization'].callback(initialization)


def recording(state):
  if state:
    status['initialization'].immutable()
    status['calibration'].immutable()
  else:
    status['initialization'].mutable()
    status['calibration'].mutable()


status['recording'].callback(recording)


def calibration(state):
  if state == 'calibrating':
    status['initialization'].immutable()
    status['calibration'].immutable()
  else:
    status['initialization'].mutable()
    status['calibration'].mutable()


status['calibration'].callback(calibration)
