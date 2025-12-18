import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA6Qct4igKqmvKKq9ntbu5GReb4IZBDCRs',
    appId: '1:106918427825:android:cc03c6b998e7c60961b690',
    messagingSenderId: '106918427825',
    projectId: 'sabelino-dogbreeds',
    storageBucket: 'sabelino-dogbreeds.firebasestorage.app',
    databaseURL: 'https://sabelino-dogbreeds-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA6Qct4igKqmvKKq9ntbu5GReb4IZBDCRs',
    appId: '1:106918427825:ios:cc03c6b998e7c60961b690',
    messagingSenderId: '106918427825',
    projectId: 'sabelino-dogbreeds',
    storageBucket: 'sabelino-dogbreeds.firebasestorage.app',
    databaseURL: 'https://sabelino-dogbreeds-default-rtdb.asia-southeast1.firebasedatabase.app',
    iosBundleId: 'com.example.dogBreedsApp',
  );

  static FirebaseOptions get currentPlatform {
    if (Platform.isAndroid) {
      return android;
    }
    if (Platform.isIOS) {
      return ios;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions.currentPlatform is not supported on this platform.',
    );
  }
}
