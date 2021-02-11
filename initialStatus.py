initialStatus = {  # just an example
    'initialization': {
        'allowedValues': ['uninitialized', 'initialized', 'deinitialized'],
        'category': 'Acquisition',
        'current': 'uninitialized',
        'mutable': True,
    },
    'rootfilename': {
        'allowedValues': [],
        'category': 'Acquisition',
        'current': '',
        'mutable': True,
    },
    'notes': {
        'allowedValues': [],  # allows anything
        'category': 'Acquisition',
        'current': '',  # string
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
    'spectrogram': {
        'category': 'Audio',
        'mutable': True,
        'current': {
            'log scaling': {
                'category': 'Audio',
                'current': True,
                'mutable': True,
            },
            'minimum frequency': {
                'category': 'Audio',
                'current': int(200),
                'allowedValues': {'min': int(1e2), 'max': int(3e4)},
                'mutable': True
            },
            'maximum frequency': {
                'category': 'Audio',
                'current': int(4e4),
                'allowedValues': {'min': int(4e4), 'max': int(1.5e5)},
                'mutable': True
            },
            'frequency resolution': {
                'category': 'Audio',
                'current': int(1e2),
                'allowedValues': [int(1e2), int(2e2), int(5e2), int(1e3)],
                'mutable': False,  # temporary
            },
            # 'displaying': {
            #     'category': 'Audio',
            #     'current': False,
            #     'mutable': True,
            # },
            'port': {
                'category': 'Audio',
                'current': 5002,
                'mutable': False,
                'allowedValues': {'min': 5002, 'max': 5100}
            },
            'pixel duration': {
                'category': 'Audio',
                'current': .0032,
                'allowedValues': {'min': .001, 'max': .005},
                'mutable': False,  # temporary
            },
            'pixel fractional overlap': {
                'category': 'Audio',
                'current': .675,
                'allowedValues': {'min': .25, 'max': .75},
                'mutable': False,  # temporary
            },
            'noise correction': {
                'category': 'Audio',
                'current': True,
                'mutable': True
            },
            'default': {
                'category': 'Audio',
                'current': True,
                'mutable': False
            }
        }
    },
    'read rate': {
        'category': 'Audio',
        'current': 2,
        'allowedValues': {'min': 2, 'max': 5},
        'mutable': False,
    },
    'camera count': {
        'category': 'Video',
        'current': 4,
        'allowedValues': {'min': 1, 'max': 7},
        'mutable': False,
    },
    'calibration': {
        'category': 'Video',
        'mutable': True,
        'current': {
            'is calibrating': {
                'category': 'Video',
                'mutable': True,
                'current': False
            },
            'camera number': {
                'category': 'Video',
                'mutable': True,
                'current': 0,
                'allowedValues': {'min': 0, 'max': 6}
            },
            'calibration type': {
                'category': 'Video',
                'mutable': True,
                'current': 'Intrinsic',
                'allowedValues': ['Intrinsic', 'Extrinsic']
            }
        }
    }
}

serialNumbers = [17391304, 17391290, 19287342, 19412282]
for i in range(4):
  initialStatus[f'camera {i}'] = {
      'category': 'Video',
      'mutable': True,
      'current': {  # create a nested dict
          'serial number': {
              'category': 'Video',
              'mutable': False,
              # TODO: just an example, obviously we would want to match these on assignment
              'current': serialNumbers[i],
              'allowedValues': serialNumbers,
          },
          'last intrinsic': {
              'category': 'Video',
              'mutable': False,
              'current': 0,  # unix timestamp
              'allowedValues': {'min': 0, 'max': int(1e10)}
          },
          'last extrinsic': {
              'category': 'Video',
              'mutable': False,
              'current': 0,  # unix timestamp
              'allowedValues': {'min': 0, 'max': int(1e10)}
          },
          'port': {
              'category': 'Video',
              'current': 5003 + i,
              'mutable': False,
              'allowedValues': {'min': 5002, 'max': 5100}
          },
          'aspect ratio': {
              'category': 'Video',
              'current': 1.25
              'mutable': False,
              'allowedValues': [1.25]
          }
          #   'displaying': {
          #       'category': 'Video',
          #       'mutable': True,
          #       'current': False
          #   },
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

# print(f'initial status: {initialStatus}')
