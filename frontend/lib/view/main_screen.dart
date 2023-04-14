import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/view/components/user_permission_view.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MainScreen'),
      ),
      body: Center(
        child: UserPermissionView(),
      ),
    );
  }
}
