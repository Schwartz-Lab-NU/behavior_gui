initialStatus = {  # just an example
    'initialization': {
        'allowedValues': ['uninitialized', 'initialized', 'deinitialized'],
        'category': 'Acquisition',
        'current': 'uninitialized',
    },
    'calibration': {
        'allowedValues': ['uncalibrated', 'calibrated', 'intrinsic', 'extrinsic', 'calibrating intrinsic', 'calibrating extrinsic'],
        'category': 'Video',
        'current': 'uncalibrated',
    },
    'sample frequency': {
        'allowedValues': {'min': int(1e4), 'max': int(1e6)},
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
    },
    'video0.display': {
        'category': 'Acqusition',
        'current': False,
    },
    'video1.display': {
        'category': 'Acqusition',
        'current': False,
    },
    'video2.display': {
        'category': 'Acqusition',
        'current': False,
    },
    'video3.display': {
        'category': 'Acqusition',
        'current': False,
    },
    'video4.display': {
        'category': 'Acqusition',
        'current': False,
    },
    'audio.display': {
        'category': 'Acqusition',
        'current': False,
    }
}
