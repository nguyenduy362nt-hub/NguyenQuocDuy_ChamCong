import 'package:geolocator/geolocator.dart';

import 'api.dart';

class LocationHelper {
  /// Lấy vị trí hiện tại (xin quyền nếu cần). Ném ApiException với thông báo tiếng Việt nếu thất bại.
  static Future<Position> current() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw ApiException('Dịch vụ vị trí đang tắt. Hãy bật Location trên thiết bị / máy ảo.');
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied) {
      throw ApiException('Bạn đã từ chối quyền truy cập vị trí');
    }
    if (perm == LocationPermission.deniedForever) {
      throw ApiException('Quyền vị trí bị chặn vĩnh viễn, hãy cấp lại trong Cài đặt ứng dụng');
    }
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)),
      );
    } catch (_) {
      throw ApiException('Không lấy được vị trí. Trên máy ảo: ... → Location → đặt vị trí rồi nhấn "Send".');
    }
  }
}
