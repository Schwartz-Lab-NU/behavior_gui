initialStatus = {  # just an example
    'initialization': {
        'allowedValues': ['uninitialized', 'initialized', 'deinitialized'],
        'category': 'Acquisition',
        'current': 'uninitialized',
        # TODO:
        # 'callback': ag.functionthatWrapsaroundRun(str),
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
    }
    # 'video0 displaying': {
    #     'category': 'Video',
    #     'current': False,
    #     'mutable': True,
    #     #request displaying = True
    #         #if requesting true, start a thread that calls 'predisplay'
    #         #thread will periodically call predisplay and then emit annotation data to server

    #     #request displaying = False
    #         #close thread
    # }
}
