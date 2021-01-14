initialStatus = {  # just an example
    'initialization': {
        'allowedValues': ['uninitialized', 'initialized', 'deinitialized'],
        'category': 'Acquisition',
        'current': 'uninitialized',
        'mutable': True,
        # 'onChange': ag.start
    },
    'calibration': {
        'allowedValues': ['uncalibrated', 'calibrated', 'intrinsic', 'extrinsic', 'calibrating intrinsic', 'calibrating extrinsic'],
        'category': 'Video',
        'current': 'uncalibrated',
        'mutable': True,
    },
    'sample frequency': {
        'allowedValues': {'min': int(1e4), 'max': int(1e6)},
        'category': 'Audio',
        'current': int(3e5),
        'mutable': True,
    },
    'frame rate': {
        'allowedValues': [10, 15, 20, 25, 30],
        'category': 'Video',
        'current': 15,
        'mutable': True,
    },
    'recording': {
        'category': 'Acquisition',
        'current': False,
        'mutable': True,
    },
    'video0.display': {
        'category': 'Acqusition',
        'current': False,
        'mutable': True,
    },
    'video1.display': {
        'category': 'Acqusition',
        'current': False,
        'mutable': True,
    },
    'video2.display': {
        'category': 'Acqusition',
        'current': False,
        'mutable': True,
    },
    'video3.display': {
        'category': 'Acqusition',
        'current': False,
        'mutable': True,
    },
    'video4.display': {
        'category': 'Acqusition',
        'current': False,
        'mutable': True,
    },
    'audio.display': {
        'category': 'Acqusition',
        'current': False,
        'mutable': True,
    }
}
