import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/repository/web3_repository.dart';
import 'package:frontend/util/ecdh_helper.dart';
import 'package:frontend/view/components/recording_view.dart';

class UserPermissionView extends StatefulWidget {
  UserPermissionView({Key? key}) : super(key: key);

  @override
  State<UserPermissionView> createState() => _UserPermissionViewState();
}

class _UserPermissionViewState extends State<UserPermissionView> {
  BigInt _sharedKey = BigInt.zero;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    setState(() {
      _sharedKey = _calcSharedKey() ?? BigInt.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
            onPressed: () {
              //! TODO: request permission
              // Web3Repository().requestPermission();

              // if success Transaction
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => RecordingView(
                            sharedSecret: _sharedKey,
                          )));
            },
            child: Text('Request Permission')),
      ],
    );
  }

  BigInt? _calcSharedKey() {
    final pri = Web3Repository().getPrivateKey();
    final pub = Web3Repository().publicKey;
    if (null == pri || null == pub) {
      debugPrint("_calcSharedKey publicKey: $pub");
      debugPrint("_calcSharedKey privateKey: $pri");
      return null;
    }
    final _sharedKey = ECDHHelper().generateECDHSharedSecret(pri, pub);
    final _sharedKeyHex = _sharedKey.toRadixString(16);
    print('shared key: $_sharedKeyHex');

    return _sharedKey;
  }
}
