import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    // شغال على Android و iOS كمان دلوقتي
    return android;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyApvE5ujAeaVkZ2iRAiLXtiu56t7-ighoI',
    appId: '11:985459317658:web:bee1f2fd2e4c16df74f823',
    messagingSenderId: '985459317658',
    projectId: 'myapp-d9024',
    authDomain: 'myapp-d9024.firebaseapp.com',
    storageBucket: 'myapp-d9024.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyApvE5ujAeaVkZ2iRAiLXtiu56t7-ighoI', // نفس الـ apiKey
    appId: '11:985459317658:android:bee1f2fd2e4c16df74f823', // غيّر الآخر لـ android
    messagingSenderId: '985459317658',
    projectId: 'myapp-d9024',
    storageBucket: 'myapp-d9024.firebasestorage.app',
  );
}