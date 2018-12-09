import 'package:flutter/material.dart';

class BlackLoadingPage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: new CircularProgressIndicator(
          // valueColor: Colors.white,
        ),
      ),
    );
  }

}