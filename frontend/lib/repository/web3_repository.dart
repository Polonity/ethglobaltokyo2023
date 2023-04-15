import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

// import 'package:frontend/abi/contract.g.dart';
import 'package:frontend/abi/RadioPermissionController.g.dart';
import 'package:frontend/config/constants.dart';
import 'package:frontend/util/web3_credentials.dart';
import 'package:http/http.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:flutter/material.dart';
import 'package:web3dart/src/utils/typed_data.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

/// dapps
class Web3Repository {
  static Web3Repository? _instance;

  factory Web3Repository() {
    if (_instance == null) {
      _instance = new Web3Repository._();
    }

    return _instance!;
  }

  Web3Repository._();

  Web3EasyCredentials? _credential;

  final _privateKeyAsMapKey = "privateKey";

  final _secureStorage = FlutterSecureStorage();

  /// chain infomations
  bool get isInOperatingChain => true;
  bool get isConnected => (null != _credential) ? true : false;
  String? currentAddress;

  String? errorMessage;

  String? _privateKey;
  String? get privateKey => _privateKey;

  String? _publicKey;
  String? get publicKey => _publicKey;

  Future<void> init() async {
    print("Web3Repository::init");
    await _secureStorage.deleteAll();
    await _secureStorage.containsKey(key: _privateKeyAsMapKey);
    await loadCredential();
  }

  Future<bool> loadCredential() async {
    debugPrint("loadCredential");

    String? _privateKey = await _secureStorage.read(key: _privateKeyAsMapKey);
    if (null == _privateKey || 64 != _privateKey.length) {
      // private key not found
      return createCredential();
    }

    await setCredential(_privateKey);
    return true;
  }

  Future<bool> createCredential() async {
    print("createCredential");
    // create new private key
    // generate a new key randomly
    final rng = Random.secure();
    final EthPrivateKey _privateKey = EthPrivateKey.createRandom(rng);
    final String _newPrivateKey = bytesToHex((0 == _privateKey.privateKey.first) ? _privateKey.privateKey.sublist(1) : _privateKey.privateKey);
    if (false == await setCredential(_newPrivateKey)) {
      errorMessage = "Failed to create credential";
      return false;
    }
    // save private key
    await _secureStorage.write(key: _privateKeyAsMapKey, value: _newPrivateKey);
    return true;
  }

  Future<bool> setCredential(String _secret) async {
    if (64 != _secret.length) {
      errorMessage = "Invalid private key";
      Future.error("private key length is not 64");
      return false;
    }

    try {
      _credential = Web3EasyCredentials.fromHex(_secret);
      currentAddress = (await _credential!.extractAddress()).hexEip55;
      _publicKey = bytesToHex(_credential!.encodedPublicKey, include0x: true);

      debugPrint("currentAddress: $currentAddress");
      debugPrint("publicKey: $_publicKey");
      debugPrint("privateKey: $_secret");
    } catch (e) {
      debugPrint(e.toString());
      Future.error(e.toString());
      return false;
    }
    return true;
  }

  String? getPrivateKey() {
    return bytesToHex(_credential!.privateKey);
  }

  Future<String?> getPublicKey() async {
    final privKey = await _secureStorage.read(key: _privateKeyAsMapKey);
    if (null == privKey) {
      return null;
    }
    final _credential = Web3EasyCredentials.fromHex(privKey);
    return bytesToHex(_credential.encodedPublicKey);
  }

  deleteCredential() async {
    await _secureStorage.delete(key: _privateKeyAsMapKey);
  }

  String getPubkeyAsHexString() {
    return bytesToHex(_credential!.encodedPublicKey);
  }

  String getPhysicalAssetPublicKey() {
    return '3b3f9b38988da8941bf98c44791e42d92bfea57a7cc371c6740d5d68d71f2f6b0c3dab7179a1ba434cab6d52edc227e98aefd90d9a8615a68e92c94ce0025af3';
  }

  Future<TransactionReceipt?> startUserEngagement(String _hashK_UA) async {
    if (null == _credential) {
      // not connected
      return null;
    }
    debugPrint("addr $currentAddress");

    final client = Web3Client(Constants.rpcUrl, Client());
    client.printErrors = true;
    RadioPermissionController _contract = RadioPermissionController(address: EthereumAddress.fromHex(Constants.contractAddress), client: client, chainId: Constants.chainId);

    final _transaction = Transaction(
      from: EthereumAddress.fromHex(currentAddress!),
      nonce: await client.getTransactionCount(EthereumAddress.fromHex(currentAddress!), atBlock: BlockNum.pending()),
      maxGas: 5000000,

      gasPrice: EtherAmount.fromUnitAndValue(EtherUnit.gwei, BigInt.from(70)),
      // EIP-1559
      maxFeePerGas: EtherAmount.fromUnitAndValue(EtherUnit.gwei, BigInt.from(70)),
      maxPriorityFeePerGas: EtherAmount.fromUnitAndValue(EtherUnit.gwei, BigInt.from(30)),
    );

    debugPrint("signing...");

    String? tx;
    try {
      tx = await _contract.startUserEngagement(hexToInt(currentAddress!), BigInt.zero, hexToInt(_hashK_UA), credentials: _credential!);
      debugPrint("tx: $tx");
    } catch (e) {
      debugPrint(e.toString());
      errorMessage = e.toString();
    }

    final receipt = await _waitTransaction(client, tx!);

    client.dispose();

    return receipt;
  }

  // wait transaction to be confirmed
  Future<TransactionReceipt?> _waitTransaction(Web3Client _client, String _tx) async {
    int _cnt = 0;
    const int cntMax = 600; // 10min
    TransactionReceipt? _receipt;

    while (true) {
      _receipt = await _getTransactionReceipt(_client, _tx);
      if (null != _receipt) {
        debugPrint("receipt: ${_receipt}");
        break;
      }
      if (_cnt++ >= cntMax) {
        break;
      }
      await Future.delayed(const Duration(seconds: 1));
      debugPrint("retry: $_cnt");
    }

    return _receipt;
  }

  // get transaction receipt to be confirmed
  Future<TransactionReceipt?> getTransactionReceipt(String rpcUrl, String _tx) async {
    TransactionReceipt? _receipt;
    final Web3Client _client = Web3Client(rpcUrl, Client());

    try {
      _receipt = await _client.getTransactionReceipt(_tx);
    } catch (e) {
      debugPrint("getTransactionReceipt error: $e");
    }

    return _receipt;
  }

  // get transaction receipt to be confirmed
  Future<TransactionReceipt?> _getTransactionReceipt(Web3Client _client, String _tx) async {
    TransactionReceipt? _receipt;

    try {
      _receipt = await _client.getTransactionReceipt(_tx);
    } catch (e) {
      debugPrint("getTransactionReceipt error: $e");
    }

    return _receipt;
  }
}
