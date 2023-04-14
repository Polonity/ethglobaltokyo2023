import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/ecc/api.dart' show ECPoint;
import 'package:web3dart/src/crypto/secp256k1.dart' as secp256k1;
import 'package:collection/collection.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web3dart/src/utils/typed_data.dart';
import 'package:crypto/crypto.dart';

/// Credentials that can sign payloads with an Ethereum private key.
class Web3EasyCredentials extends EthPrivateKey {
  static const _messagePrefix = '\u0019Ethereum Signed Message:\n';

  /// Creates a private key from a byte array representation.
  ///
  /// The bytes are interpreted as an unsigned integer forming the private key.
  Web3EasyCredentials(Uint8List privateKey) : super(privateKey);

  /// Parses a private key from a hexadecimal representation.
  Web3EasyCredentials.fromHex(String hex) : this(hexToBytes(hex));

  /// Creates a new, random private key from the [random] number generator.
  ///
  /// For security reasons, it is very important that the random generator used
  /// is cryptographically secure. The private key could be reconstructed by
  /// someone else otherwise. Just using [Random()] is a very bad idea! At least
  /// use [Random.secure()].
  factory Web3EasyCredentials.createRandom(Random random) {
    final key = generateNewPrivateKey(random);
    return Web3EasyCredentials(intToBytes(key));
  }

  @override
  Future<MsgSignature> signToSignature(Uint8List payload, {int? chainId, bool isEIP1559 = false}) async {
    final signature = secp256k1.sign(payload, privateKey);

    // https://github.com/ethereumjs/ethereumjs-util/blob/8ffe697fafb33cefc7b7ec01c11e3a7da787fe0e/src/signature.ts#L26
    // be aware that signature.v already is recovery + 27
    int chainIdV;
    if (isEIP1559) {
      chainIdV = signature.v - 27;
    } else {
      chainIdV = chainId != null ? (signature.v - 27 + (chainId * 2 + 35)) : signature.v;
    }
    return MsgSignature(signature.r, signature.s, chainIdV);
  }

  /// Signs an Ethereum specific signature. This method is equivalent to
  /// [sign], but with a special prefix so that this method can't be used to
  /// sign, for instance, transactions.

  @override
  Future<Uint8List> signPersonalMessage(Uint8List payload, {int? chainId}) {
    final prefix = _messagePrefix + payload.length.toString();
    final prefixBytes = ascii.encode(prefix);

    // will be a Uint8List, see the documentation of Uint8List.+
    final concat = uint8ListFromList(prefixBytes + payload);

    return super.sign(keccak256(concat), chainId: chainId);
  }

  /// Signs an Spot challenge message. This method is equivalent to
  /// [sign], but with a special prefix so that this method can't be used to
  /// sign, for instance, transactions.
  Future<Uint8List> signSpotChallengeMessage(Uint8List payload, {int? chainId}) {
    return super.sign(Uint8List.fromList(sha256.convert(payload).bytes), chainId: chainId);
  }
}
