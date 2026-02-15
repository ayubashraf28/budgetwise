import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

@immutable
class DeviceInfoSnapshot {
  final String appVersion;
  final String platform;
  final String osVersion;
  final String deviceModel;

  const DeviceInfoSnapshot({
    required this.appVersion,
    required this.platform,
    required this.osVersion,
    required this.deviceModel,
  });
}

class DeviceInfoHelper {
  DeviceInfoHelper._();

  static Future<DeviceInfoSnapshot> collect() async {
    final packageInfo = await _safePackageInfo();
    final appVersion = packageInfo == null
        ? 'unknown'
        : '${packageInfo.version}+${packageInfo.buildNumber}';

    if (kIsWeb) {
      return DeviceInfoSnapshot(
        appVersion: appVersion,
        platform: 'web',
        osVersion: 'unknown',
        deviceModel: 'web',
      );
    }

    final deviceInfo = DeviceInfoPlugin();

    try {
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        return DeviceInfoSnapshot(
          appVersion: appVersion,
          platform: 'android',
          osVersion: info.version.release,
          deviceModel:
              '${info.manufacturer} ${info.model}'.trim().ifEmpty('unknown'),
        );
      }
      if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        return DeviceInfoSnapshot(
          appVersion: appVersion,
          platform: 'ios',
          osVersion: info.systemVersion,
          deviceModel: info.utsname.machine.ifEmpty('unknown'),
        );
      }
      if (Platform.isMacOS) {
        final info = await deviceInfo.macOsInfo;
        return DeviceInfoSnapshot(
          appVersion: appVersion,
          platform: 'macos',
          osVersion: info.osRelease,
          deviceModel: info.model.ifEmpty('unknown'),
        );
      }
      if (Platform.isWindows) {
        final info = await deviceInfo.windowsInfo;
        return DeviceInfoSnapshot(
          appVersion: appVersion,
          platform: 'windows',
          osVersion: info.displayVersion,
          deviceModel: info.computerName.ifEmpty('unknown'),
        );
      }
      if (Platform.isLinux) {
        final info = await deviceInfo.linuxInfo;
        return DeviceInfoSnapshot(
          appVersion: appVersion,
          platform: 'linux',
          osVersion: info.version ?? 'unknown',
          deviceModel: info.prettyName.ifEmpty('unknown'),
        );
      }
    } catch (_) {
      // Keep fall-through defaults when device probes fail.
    }

    return DeviceInfoSnapshot(
      appVersion: appVersion,
      platform: 'unknown',
      osVersion: 'unknown',
      deviceModel: 'unknown',
    );
  }

  static Future<PackageInfo?> _safePackageInfo() async {
    try {
      return await PackageInfo.fromPlatform();
    } catch (_) {
      return null;
    }
  }
}

extension on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}
