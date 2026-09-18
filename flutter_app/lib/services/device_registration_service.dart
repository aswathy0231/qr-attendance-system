import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceRegistrationService {
  static const String _deviceUuidKey = 'device_uuid';

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final Uuid _uuid = const Uuid();

  /// Returns the same UUID every time this app is opened
  /// on this device.
  Future<String> getDeviceUuid() async {
    final prefs = await SharedPreferences.getInstance();

    // Check whether a UUID was already generated.
    String? deviceUuid = prefs.getString(_deviceUuidKey);

    if (deviceUuid != null && deviceUuid.isNotEmpty) {
      return deviceUuid;
    }

    // Generate a new UUID for this app installation.
    deviceUuid = _uuid.v4();

    // Store it locally.
    await prefs.setString(_deviceUuidKey, deviceUuid);

    return deviceUuid;
  }

  /// Gets a readable name for the Android device.
  Future<String> getDeviceName() async {
    try {
      final androidInfo = await _deviceInfo.androidInfo;

      return '${androidInfo.manufacturer} ${androidInfo.model}';
    } catch (e) {
      return 'Android Device';
    }
  }
}