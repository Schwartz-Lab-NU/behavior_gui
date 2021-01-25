import testDefs
#import AcquisitionGroup
# from utils.audio_settings import audio_settings

global status
global ag

status = testDefs.initialStatus
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


ag = FakeAcqGroup()
