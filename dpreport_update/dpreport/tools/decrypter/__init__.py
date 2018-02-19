import os
import encrypt as enc
import logging
import wave

import tempfile as tf
import subprocess as sp
from concurrent.futures import ProcessPoolExecutor as Pool

logger = logging.getLogger(__name__)

SCRATCH_DIR = '/dev/shm/audioqc'

def unlock(file_path, passphrase):
    # Unlock file
    logger.info('Unlocking {FILE}'.format(FILE=file_path))
    return unlock_file(file_path, passphrase)

def unlock_file(path, passphrase):
    try:
        with open(path, 'rb') as locked_file:
            key = enc.key_from_file(locked_file, passphrase)

            if path.endswith('.csv.lock'):
                return text_handler(locked_file, key)
            elif path.endswith('.wav.lock'):
                return wav_handler(locked_file, key)
            elif path.endswith('.mp4.lock'):
                if not os.path.exists(SCRATCH_DIR):
                    os.makedirs(SCRATCH_DIR)
                return mp4_handler(path, key)
            else:
                logger.error('Unsupported locked file {}'.format(path))
                return None

    except Exception as e:
        logger.error(e)
        return None

def text_handler(locked_file, key):
    text_value = ''
    for chunk in enc.decrypt(locked_file, key):
        text_value += chunk
    return text_value

def wav_handler(locked_file, key):
    reader = enc.buffer(enc.decrypt(locked_file, key))
    return wave.open(reader, 'r')

# Credit goes to tokeefe
def mp4_handler(file_path, key):
    _mp4 = None
    try:
        with tf.NamedTemporaryFile(dir=SCRATCH_DIR, delete=False) as tmp:
            with open(file_path, 'rb') as fp:
                for chunk in enc.decrypt(fp, key):
                    tmp.write(chunk)
            _mp4 = tmp.name
        _wav = None
        with tf.NamedTemporaryFile(dir=SCRATCH_DIR, suffix='.wav') as tmp_wav:
            cmd = ['ffmpeg', '-i', _mp4, '-ab', '160k', '-ac',
                    '2', '-ar', '44100', '-vn', '-y', tmp_wav.name]
            sp.check_call(cmd, stderr=sp.PIPE, stdout=sp.PIPE)
            os.remove(_mp4)
            return wave.open(tmp_wav.name, 'r')
    except Exception as e:
        logger.error(e)
        return None
