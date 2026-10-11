import 'package:flutter/material.dart';

import 'app/ravapecont_app.dart';
import 'core/firebase/firebase_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  runApp(const RavapecontApp());
}
