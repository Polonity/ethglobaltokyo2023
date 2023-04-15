import 'dart:math';
import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/curves/secp256k1.dart';
import 'package:web3dart/crypto.dart';

class ECDHHelper {
  static ECDomainParameters _domainParams = ECCurve_secp256k1();
  ECDomainParameters get domainParams => _domainParams;

  String generateECDHSharedSecret(String userPrivateKeyHex, String otherUserPublicKeyHex) {
    // Curve used for ECDH

    // Get private key from hex
    BigInt privateKey = BigInt.parse(userPrivateKeyHex, radix: 16);

    // Get public key x and y coordinates from hex
    BigInt publicKeyX = BigInt.parse(otherUserPublicKeyHex.substring(0, 64), radix: 16);
    BigInt publicKeyY = BigInt.parse(otherUserPublicKeyHex.substring(64, 128), radix: 16);

    // Create public key point
    ECPoint publicKeyPoint = _domainParams.curve.createPoint(publicKeyX, publicKeyY);

    // Generate shared key
    ECPoint? sharedKeyPoint = publicKeyPoint * privateKey;

    // Convert to hex
    BigInt sharedKey = (sharedKeyPoint!.x!.toBigInteger()! | sharedKeyPoint.y!.toBigInteger()!);
    String sharedKeyHex = '0x' + sharedKey.toRadixString(16).padLeft(64, '0');

    print('SHARED KEY: $sharedKeyHex');
    return sharedKeyHex;
  }

  BigInt generateECDHSharedSecretAsBigInt(String userPrivateKeyHex, String otherUserPublicKeyHex) {
    final privateKeyBigInt = BigInt.parse(userPrivateKeyHex, radix: 16);
    final privateKey = ECPrivateKey(privateKeyBigInt, _domainParams);

    final publicKeyPoint = getECPoint(otherUserPublicKeyHex.substring(0, 64), otherUserPublicKeyHex.substring(64, 128));
    final otherUserPublicKey = ECPublicKey(publicKeyPoint, _domainParams);

    final ECDHBasicAgreement ecdhAgreement = ECDHBasicAgreement();
    ecdhAgreement.init(privateKey);
    return ecdhAgreement.calculateAgreement(otherUserPublicKey);
  }

  ECPoint getECPoint(String xHexString, String yHexString) {
    BigInt xBigInt = BigInt.parse(xHexString, radix: 16);
    BigInt yBigInt = BigInt.parse(yHexString, radix: 16);
    ECPoint ecPoint = _domainParams.curve.createPoint(xBigInt, yBigInt);
    return ecPoint;
  }
}
