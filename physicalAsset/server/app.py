from flask import Flask
from flask import render_template, request
from flask_cors import CORS, cross_origin
import os
from flask import jsonify
from eth_utils import keccak
from Crypto.Cipher import AES
from tinyec import registry
import tinyec.ec as ec
import base64
import json
import logging
import subprocess

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


app = Flask(__name__)
CORS(app)

env = {}

# read .env file
PUBLIC_KEY = '0x3b3f9b38988da8941bf98c44791e42d92bfea57a7cc371c6740d5d68d71f2f6b0c3dab7179a1ba434cab6d52edc227e98aefd90d9a8615a68e92c94ce0025af3'
PRIVATE_KEY = '0xc340a2006b4e66676bab00fd91d083d76f5af46707e2d3b61ead3ef497273636'
# PUBLIC_KEY = os.environ['PUBLIC_KEY']
# PRIVATE_KEY = os.environ['PRIVATE_KEY']
# CONTRACT_ADDRESS = os.environ['CONTRACT_ADDRESS']

logger.info('PUBLIC_KEY: ' + PUBLIC_KEY)
logger.info('PRIVATE_KEY: ' + PRIVATE_KEY)
# logger.info('CONTRACT_ADDRESS: ' + CONTRACT_ADDRESS)

AUDIO_FILE_NAME = './decrypted_audio.wav'
RADIO_COMMAND = f'sudo /home/gohiki/workspace/radio/pifm {AUDIO_FILE_NAME}'

# set publickey to contract if have not set yet


curve = registry.get_curve('secp256k1')


def calcSharedKey(publicKeyHex: str, privateKeyHex: str) -> str:

    # ========================================
    # generate shared key from user public key
    # ========================================
    # retrieve private key from secure module
    private_key_device = int(privateKeyHex, 16)

    public_key_user_point = ec.Point(curve, int('0x' + publicKeyHex[2:66], 0), int(
        '0x' + publicKeyHex[66:130], 0))

    # generate shared key
    shared_key = private_key_device * public_key_user_point

    # convert to hex
    shared_key_bytes = (shared_key.x | shared_key.y).to_bytes(
        32, byteorder='big')
    shared_key_hex = '0x' + shared_key_bytes.hex()

    logger.debug('SHARED KEY\t: %s', shared_key_hex)

    return shared_key_hex


@app.route('/user/operation', methods=['POST'])
def upload_file():
    payload = request.json

    #! should be recover from user signature for keccak(audio)
    user = payload.get('user')

    #! should be recover from user signature for keccak(audio)
    userPublicKey = payload.get('publicKey')

    audioAsBase64 = payload.get('audio')

    logger.info('** Incoming request✨')
    logger.info('\tuser: ' + user)
    logger.info('\publickey: ' + userPublicKey)
    logger.info('\taudio(base64): ' + str(len(audioAsBase64)) + ' bytes')

    # base64 decode
    audio_as_encrypted = base64.b64decode(audioAsBase64)
    logger.info('\taudio: ' + str(len(audio_as_encrypted)) + ' bytes')

    # generate ECDH key
    shared_key_hex = calcSharedKey(
        userPublicKey, PRIVATE_KEY)
    # shared_key_hex = '0x09001d98af370e9957dcacbf2719d4f1af4ce288a93e620caf3e850325ecba2f'
    logger.info('SHARED KEY\t: %s', shared_key_hex)

    # hash shared key as keccak256
    shared_key_hash_bytes = keccak(bytes.fromhex(
        shared_key_hex[2:]))
    shared_key_hash_hex = '0x' + shared_key_hash_bytes.hex()
    logger.info('SHARED KEY HASH\t: %s', shared_key_hash_hex)

    # !check shared key hash is same as contract
    # if shared_key_hash_hex != CONTRACT_ADDRESS:
    #     return jsonify({'message': 'error: shared key hash is not same as contract address!'})

    # decrypt data
    iv = audio_as_encrypted[:16]
    cipher_data = audio_as_encrypted[16:]
    cipher = AES.new(bytes.fromhex(
        shared_key_hex[2:]), AES.MODE_CBC, iv)
    decrypted_compressed_data = cipher.decrypt(cipher_data)

    # erase padding as PKCS#7
    pad_len = decrypted_compressed_data[-1]
    decrypted_compressed_data = decrypted_compressed_data[:-pad_len]

    # save data
    with open(AUDIO_FILE_NAME, 'wb') as f:
        f.write(decrypted_compressed_data)
        logger.info('📝 write decrypted data to %s(%d bytes)',
                    AUDIO_FILE_NAME, len(decrypted_compressed_data))

    # execute system command
    subprocess.call(RADIO_COMMAND, shell=True)

    return jsonify({'message': 'success!'})


@app.route('/test', methods=['GET'])
def test():
    return jsonify({'message': 'test'})


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5454)
