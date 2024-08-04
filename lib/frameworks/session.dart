import 'package:squarecloud_app/frameworks/securestorage.dart';
import 'package:squarecloud_app/frameworks/squareapi.dart';

class Session {
  late String? AUTH_TOKEN;
  late final SquareAPI? _api;

  Session ({ String? authToken }) {
    SecureStorage.init();
    if (authToken != null) {
      AUTH_TOKEN = authToken;
      SecureStorage.write("square_key", authToken);
      return;
    }
  }

  Future<void> init() async {
    SecureStorage.init();
    String? key = await SecureStorage.read("square_key");
    if (key != null) {
      AUTH_TOKEN = key;
    }
  }

  Future<bool> isValid() async {
    if (AUTH_TOKEN == null) {
      return false;
    }

    _api = SquareAPI(AUTH_TOKEN!);
    final response = await _api!.get("/v2/users/me");

    if (response["status"] == "success") {
      return true;
    } else {
      if (response["error"] == "ACCESS_DENIED") {
        return false;
      } else {
        return true;
      }
    }
  }

  SquareAPI getAPI() {
    _api ??= SquareAPI(AUTH_TOKEN!);
    return _api!;
  }
}