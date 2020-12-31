initialStatus = { #just an example
  'initialization': {
    'allowedValues' : ['uninitialized', 'initialized', 'deinitialized'],
    'category': 'Acquisition',
    'current': 'uninitialized',
  },
  'sample frequency' : {
    'allowedValues' : {'min': int(1e4), 'max': int(1e6)},
    'category': 'Audio',
    'current': int(3e5),
  },
  'frame rate': {
    'allowedValues': [10, 15, 20, 25, 30],
    'category': 'Video',
    'current': 15,
  },
  'recording': {
    'category': 'Acquisition',
    'current': False,
  }
}