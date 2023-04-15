import 'package:flutter/material.dart';
import 'package:frontend/view/main_screen.dart';

class LandingView extends StatefulWidget {
  LandingView({Key? key}) : super(key: key);

  @override
  State<LandingView> createState() => _LandingViewState();
}

class _LandingViewState extends State<LandingView> {
  Future? _future;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _future = Future.delayed(Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    onLoaded(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('WorldRadio'),
      ),
      body: Center(
        child: FutureBuilder(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                onLoaded(context);
              }
              return const CircularProgressIndicator(
                color: Colors.deepPurple,
                strokeWidth: 1.5,
              );
            }),
      ),
    );
  }

  onLoaded(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const MainScreen()));
  }
}
