import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseOptionsDev {
  FirebaseOptionsDev._();

  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'FirebaseOptionsDev are only configured for Android and iOS.',
        );
    }
  }

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: _required(
          const String.fromEnvironment('FIREBASE_DEV_ANDROID_API_KEY'),
          'FIREBASE_DEV_ANDROID_API_KEY',
        ),
        appId: _required(
          const String.fromEnvironment('FIREBASE_DEV_ANDROID_APP_ID'),
          'FIREBASE_DEV_ANDROID_APP_ID',
        ),
        messagingSenderId: _required(
          const String.fromEnvironment('FIREBASE_DEV_MESSAGING_SENDER_ID'),
          'FIREBASE_DEV_MESSAGING_SENDER_ID',
        ),
        projectId: _required(
          const String.fromEnvironment('FIREBASE_DEV_PROJECT_ID'),
          'FIREBASE_DEV_PROJECT_ID',
        ),
        storageBucket:
            const String.fromEnvironment('FIREBASE_DEV_STORAGE_BUCKET'),
      );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: _required(
          const String.fromEnvironment('FIREBASE_DEV_IOS_API_KEY'),
          'FIREBASE_DEV_IOS_API_KEY',
        ),
        appId: _required(
          const String.fromEnvironment('FIREBASE_DEV_IOS_APP_ID'),
          'FIREBASE_DEV_IOS_APP_ID',
        ),
        messagingSenderId: _required(
          const String.fromEnvironment('FIREBASE_DEV_MESSAGING_SENDER_ID'),
          'FIREBASE_DEV_MESSAGING_SENDER_ID',
        ),
        projectId: _required(
          const String.fromEnvironment('FIREBASE_DEV_PROJECT_ID'),
          'FIREBASE_DEV_PROJECT_ID',
        ),
        storageBucket:
            const String.fromEnvironment('FIREBASE_DEV_STORAGE_BUCKET'),
        iosBundleId:
            const String.fromEnvironment('FIREBASE_DEV_IOS_BUNDLE_ID'),
        iosClientId:
            const String.fromEnvironment('FIREBASE_DEV_IOS_CLIENT_ID'),
      );

  static String _required(String value, String key) {
    if (value.trim().isEmpty) {
      throw StateError(
        'Missing Firebase config for $key. Provide it via --dart-define.',
      );
    }
    return value.trim();
  }
}
