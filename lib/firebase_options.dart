import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC4EF-4uEXIZijgAR7-pc6zCgHSjQiR23g',
    authDomain: 'rentalmanagement-2cb62.firebaseapp.com',
    databaseURL: 'https://rentalmanagement-2cb62-default-rtdb.asia-southeast1.firebasedatabase.app',
    projectId: 'rentalmanagement-2cb62',
    storageBucket: 'rentalmanagement-2cb62.firebasestorage.app',
    messagingSenderId: '1063644310518',
    appId: '1:1063644310518:web:917b7e70397321bc8975d7',
    measurementId: 'G-M2B4KQ7904',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC4EF-4uEXIZijgAR7-pc6zCgHSjQiR23g',
    authDomain: 'rentalmanagement-2cb62.firebaseapp.com',
    projectId: 'rentalmanagement-2cb62',
    storageBucket: 'rentalmanagement-2cb62.firebasestorage.app',
    messagingSenderId: '1063644310518',
    appId: '1:1063644310518:web:917b7e70397321bc8975d7',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC4EF-4uEXIZijgAR7-pc6zCgHSjQiR23g',
    authDomain: 'rentalmanagement-2cb62.firebaseapp.com',
    projectId: 'rentalmanagement-2cb62',
    storageBucket: 'rentalmanagement-2cb62.firebasestorage.app',
    messagingSenderId: '1063644310518',
    appId: '1:1063644310518:web:917b7e70397321bc8975d7',
  );
}
