# import testDefs
# import AcquisitionGroup
# from utils.audio_settings import audio_settings
from behavior_gui.initialStatus import initialStatus

global status
global ag

global printToGUI  # TODO: should be defined in socketApp.py??
# will look something like: socketio.emit("message", f"message content string")

global annotationsToGUI  # TODO: should be defined in socketApp.py??
# will look something like socketio.emit("annotation", {"streamId":0, "data": [ {"rectangle":[(p0x, p0y), ..., (p3x, p3y)]}, ... ]})

# status = testDefs.initialStatus
# ag = AcquisitionGroup.AcquisitionGroup(frame_rate=30,audio_settings=audio_settings)


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
    if type(value['current']) is dict:
      self._allowed = []  # TODO: placeholder for nested dict...
      self._current = {k: RigStatusValue(v)
                       for k, v in value['current'].items()}
    elif 'allowedValues' in value.keys():
      self._allowed = value['allowedValues']
      self._current = value['current']
    elif type(value['current'] is bool):
      self._allowed = (True, False)
      self._current = value['current']

    self._category = value['category']
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
    # TODO: check that state is allowed and parseable!
    if not self._mutable:
      raise 'Couldn\'t set status'

    if type(self._current) is dict:
      current = self._current.copy()
      try:
        print(f'goal: {state}')
        for k, v in state.items():
          print(f'attempting to set {k} to {v}')
          current[k](v)
        self._current = current
      except:
        'Couldn\'t set sub-status'
    else:
      self._current = state

    self._callback(state)

  @property
  def allowed(self):
    if type(self._current) is dict:
      return {'allowedValues': self._allowed, 'category': self._category, 'current': {k: v.allowed for k, v in self._current.items()}, 'mutable': self._mutable}
    else:
      return {'allowedValues': self._allowed, 'category': self._category, 'current': self._current, 'mutable': self._mutable}

  @property
  def update(self):
    if type(self._current) is dict:
      return {'current': {k: v.update for k, v in self._current.items()}, 'mutable': self._mutable}
    else:
      return {'current': self._current, 'mutable': self._mutable}


class RigStatus(dict):
  def __init__(self, status):
    super().__init__()
    self._status = {k: RigStatusValue(v) for k, v in status.items()}

  def __getitem__(self, key):
    return self._status[key]

  def __setitem__(self, key,  value):
    self._status[key] = value

  @ property
  def allowed(self):
    return {k: v.allowed for k, v in self._status.items()}

  @ property
  def update(self):
    return {k: v.update for k, v in self._status.items()}


ag = FakeAcqGroup()
status = RigStatus(initialStatus)
