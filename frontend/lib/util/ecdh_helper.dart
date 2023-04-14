import 'dart:math';
import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/curves/secp256k1.dart';
import 'package:web3dart/crypto.dart';

class ECDHHelper {
  static ECDomainParameters _domainParams = ECCurve_secp256k1();
  ECDomainParameters get domainParams => _domainParams;

  BigInt generateECDHSharedSecret(String userPrivateKeyHex, String otherUserPublicKeyHex) {
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
