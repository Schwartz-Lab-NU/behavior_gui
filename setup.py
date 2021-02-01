# import testDefs
#import AcquisitionGroup
# from utils.audio_settings import audio_settings
from initialStatus import initialStatus

global status
global ag

global printToGUI  # TODO: should be defined in socketApp.py??
# will look something like: socketio.emit("message", f"message content string")

global annotationsToGUI  # TODO: should be defined in socketApp.py??
# will look something like socketio.emit("annotation", {"streamId":0, "data": [ {"rectangle":[(p0x, p0y), ..., (p3x, p3y)]}, ... ]})

# status = testDefs.initialStatus
#ag = AcquisitionGroup.AcquisitionGroup(frame_rate=30,audio_settings=audio_settings)


class FakeAcqGroup:
  def __init__(self):
    self.running = False

  def stop(self):
    self.running = False

  def start(self):
    pass

  def run(self):
    self.running = True


class RigStatusValue:
  def __init__(self, value):
    # print(f'initing rsv: {value}')
    if 'allowedValues' in value.keys():
      self._allowed = value['allowedValues']
    else:
      self._allowed = (True, False)

    self._category = value['category']
    self._current = value['current']
    self._mutable = value['mutable']
    self._callback = lambda x: x

  def __getitem__(self, key):
    return self._current

  def __set__(self, instance, value):
    self._current = value

  def mutable(self):
    self._mutable = True

  def immutable(self):
    self._mutable = False

  def callback(self, fun):
    self._callback = fun

  def __call__(self, state):
    if (self._current == state) or not self._mutable:
      return
    self._current = state

    self._callback(state)

  @property
  def allowed(self):
    return {'allowedValues': self._allowed, 'category': self._category, 'current': self._current, 'mutable': self._mutable}

  @property
  def update(self):
    return {'current': self._current, 'mutable': self._mutable}


class RigStatus(dict):
  def __init__(self, status):
    self._status = {k: RigStatusValue(v) for k, v in status.items()}
    print('done initing rigstatus')
    print(self._status.keys())

  def __getitem__(self, key):
    print(f'attempting to get key: {key}')
    print(self._status.keys())
    return self._status[key]

  def __setitem__(self, key,  value):
    self._status[key] = value

  @property
  def allowed(self):
    return {k: v.allowed for k, v in self._status.items()}

  @property
  def update(self):
    return {k: v.update for k, v in self._status.items()}


ag = FakeAcqGroup()
status = RigStatus(initialStatus)
