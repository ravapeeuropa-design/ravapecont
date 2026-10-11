import 'package:flutter/material.dart';

class AppBootstrapPage extends StatelessWidget {
  const AppBootstrapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ravapecont'),
      ),
      body: const Center(
        child: Text('Ravapecont preparado'),
      ),
    );
  }
}
