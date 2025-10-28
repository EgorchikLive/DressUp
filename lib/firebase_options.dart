import 'dart:io';

import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (Platform.isAndroid) {
      return const FirebaseOptions(
        apiKey: 'AIzaSyD5ksumCHCeK5kjd3Ttworbdx2XmIkdc9g',
        appId: '1:440347985125:android:0670f1e3153c4521d4400c',
        messagingSenderId: '440347985125',
        projectId: 'dressup-e9e5a',
        // Добавьте остальные необходимые поля для Android
        storageBucket: 'dressup-e9e5a.appspot.com',
      );
    } else if (Platform.isIOS) {
      return const FirebaseOptions(
        apiKey: 'AIzaSyBJiUFZz1HFyCE9EFc4f-kiTegwO6-O-JQ',
        appId: '1:440347985125:ios:a50d797301be132dd4400c',
        messagingSenderId: '440347985125',
        projectId: 'dressup-e9e5a',
        iosBundleId: 'com.egor.dressUp',
        // Добавьте остальные необходимые поля для iOS
        storageBucket: 'dressup-e9e5a.appspot.com',
      );
    } else {
      throw UnsupportedError("Unsupported platform");
    }
  }
}
// FirebaseOptions firebaseOptions = const FirebaseOptions(
//     apiKey: 'AIzaSyDvxCOw86-4jONwdOOcZYhHScnx_jPeODo',
//     appId: '1:651756444474:android:4a9771d06af00ad1f30e03',
//     messagingSenderId: '651756444474',
//     projectId: 'yummy-5e694');