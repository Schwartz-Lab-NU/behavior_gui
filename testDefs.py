initialStatus = {  # just an example
    'initialization': {
        'allowedValues': ['uninitialized', 'initialized', 'deinitialized'],
        'category': 'Acquisition',
        'current': 'uninitialized',
        # TODO:
        # 'callback': ag.functionthatWrapsaroundRun(str),
        # 'mutable': True,
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
        # 'mutable': False,
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
    'camera0.width': {
        'allowedValues': [1280],
        'category': 'Video',
        'current': 1280
    },
    'camera0.height': {
        'allowedValues': [1024],
        'category': 'Video',
        'current': 1024
    },
    'video0.display': {  # reflects ag.Cameras[0].isDisplaying? or whatever
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
