initialStatus = {  # just an example
    'initialization': {
        'allowedValues': ['uninitialized', 'initialized', 'deinitialized'],
        'category': 'Acquisition',
        'current': 'uninitialized',
        'mutable': True,
    },
    'notes': {
        'allowedValues': [],  # allows anything
        'category': 'Acquisition',
        'current': '',  # string
        'mutable': True,
    },
    'rootfilename': {
        'allowedValues': [],
        'category': 'Acquisition',
        'current': '',
        'mutable': True,
    },
    'sample frequency': {
        'allowedValues': {'min': int(1e4), 'max': int(1e6)},
        'category': 'Audio',
        'current': int(3e5),
        'mutable': False,
    },
    'frame rate': {
        'allowedValues': [10, 15, 20, 25, 30],
        'category': 'Video',
        'current': 15,
        'mutable': False,
    },
    'recording': {
        'category': 'Acquisition',
        'current': False,
        'mutable': True,
    },
    'log scaling': {
        'category': 'Audio',
        'current': True,
        'mutable': True,
    },
    'minimum frequency': {
        'category': 'Audio',
        'current': int(1e4),
        'allowedValues': {'min': int(1e2), 'max': int(4e4)},
        'mutable': True,
    },
    'maximum frequency': {
        'category': 'Audio',
        'current': int(5e4),
        'allowedValues': {'min': int(5e4), 'max': int(1.5e5)},
        'mutable': True,
    },
    'frequency resolution': {
        'category': 'Audio',
        'current': int(1e2),
        'allowedValues': [int(1e2), int(2e2), int(5e2), int(1e3)],
        'mutable': True,
    },
    'read rate': {
        'category': 'Audio',
        'current': 1,
        'allowedValues': {'min': 1, 'max': 5},
        'mutable': False,
    },
    'camera count': {
        'category': 'Video',
        'current': 4,
        'allowedValues': {'min': 1, 'max': 7},
        'mutable': False,
    },
    'calibration' : {
        'category': 'Video',
        'mutable': True,
        'current': {
            'isCalibrating': {
                'category': 'Video',
                'mutable': True,
                'current': False
            },
            'camera number': {
                'category': 'Video',
                'mutable': True,
                'current': 0,
                'allowedValues': {'min': 0, 'max': 6}
            }
        }
    }
}

for i in range(4):
  initialStatus[f'camera {i}'] = {
      'category': 'Video',
      'mutable': True,
      'current': {  # create a nested dict
          'serialNumber': {
              'category': 'Video',
              'mutable': False,
              # TODO: just an example, obviously we would want to match these on assignment
              'current': f'ID000{i}xxx',
              'allowedValues': [f'ID000{i}xxx' for i in range(4)],
          },
          'lastIntrinsic': {
              'category': 'Video',
              'mutable': False,
              'current': 0,  # unix timestamp
              'allowedValues': {'min': 0, 'max': int(1e10)}
          },
          'lastExtrinsic': {
              'category': 'Video',
              'mutable': False,
              'current': 0,  # unix timestamp
              'allowedValues': {'min': 0, 'max': int(1e10)}
          },
          'displaying': {
              'category': 'Video',
              'mutable': True,
              'current': False
          },
        #   'processing': {
        #       'category': 'Video',
        #       'mutable': True,
        #       'current': False
        #   },
        #   'calibratingIntrinsic': {
        #       'category': 'Video',
        #       'mutable': True,
        #       'current': False
        #   },
        #   'calibratingExtrinsic': {
        #       'category': 'Video',
        #       'mutable': True,
        #       'current': False
        #   }
      }
  }

print(f'initial status: {initialStatus}')
