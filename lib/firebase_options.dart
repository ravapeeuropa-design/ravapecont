import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions are only configured for Android and Web.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBvnE0ew8S8R09m5bFkgOaxfgH-wG_r0GQ',
    appId: '1:201288342204:android:b934f588695bcbc6558eb9',
    messagingSenderId: '201288342204',
    projectId: 'ravapecont',
    storageBucket: 'ravapecont.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDGgReAvNAKqBNkl8QUGbgRLq0fBiiPwdE',
    appId: '1:201288342204:web:c8a9d9943adc02cb558eb9',
    messagingSenderId: '201288342204',
    projectId: 'ravapecont',
    authDomain: 'ravapecont.firebaseapp.com',
    storageBucket: 'ravapecont.firebasestorage.app',
    measurementId: 'G-PBWZNFF354',
  );

}