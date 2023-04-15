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
  String _sharedKey = '';
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    setState(() {
      _sharedKey = _calcSharedKey() ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
            onPressed: () async {
              //! TODO: request permission
              final recept = await Web3Repository().startUserEngagement(_sharedKey);
              if (recept == null || recept.status == false) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to request permission'),
                  ),
                );
                return;
              }
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

  String? _calcSharedKey() {
    final pri = Web3Repository().getPrivateKey();
    final pub = Web3Repository().getPhysicalAssetPublicKey();

    debugPrint("_calcSharedKey publicKey: $pub");
    debugPrint("_calcSharedKey privateKey: $pri");
    if (null == pri || null == pub) {
      return null;
    }
    final _sharedKeyHex = ECDHHelper().generateECDHSharedSecret(pri, pub);
    // final _sharedKey = ECDHHelper().generateECDHSharedSecretAsBigInt(pri, pub);
    // final _sharedKeyHex = _sharedKey.toRadixString(16);
    print('shared key: $_sharedKeyHex');

    return _sharedKeyHex;
  }
}
