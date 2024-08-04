import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:squarecloud_app/frameworks/session.dart';
import 'package:squarecloud_app/frameworks/varstore.dart';

class UploadManager {
  static Future<String?> selectFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['zip']);
    if (result != null) {
      return result.files.single.path;
    } else {
      return null;
    }
  }
  static Future<File> readFile (String path) async {
    return File(path);
  }

  static Future<String> commitApp(String path, String appId) async {
    Session session = SameProcessStorage.read("session");
    var api = session.getAPI();

    File file = await readFile(path);

    var response = await api.postFile("/v2/apps/$appId/commit?restart=true", file);
    if (response["status"] == "success") {
      return response["code"];
    } else {
      SquareLogger.error("Failed to upload app: ${response["error"]}");
      return response["code"];
    }
  }

  static Future<String> uploadApp(String path) async {
    Session session = SameProcessStorage.read("session");
    var api = session.getAPI();

    File file = await readFile(path);

    var response = await api.postFile("/v2/apps", file);
    if (response["status"] == "success") {
      return response["code"];
    } else {
      SquareLogger.error("Failed to upload app: ${response["error"]}");
      return response["code"];
    }
  }
}