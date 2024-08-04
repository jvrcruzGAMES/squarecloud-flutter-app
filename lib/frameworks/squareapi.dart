import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class SquareAPI {
  static const String BASE_URL = "https://api.squarecloud.app";
  late final String AUTH_TOKEN;

  SquareAPI(this.AUTH_TOKEN);

  Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await http.get(Uri.parse(BASE_URL + endpoint), headers: {
      "Authorization": AUTH_TOKEN
    });

    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic>? body) async {
    final response = await http.post(Uri.parse(BASE_URL + endpoint), headers: {
      "Authorization": AUTH_TOKEN,
      "Content-Type": "application/json"
    }, body: json.encode(body));

    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> delete (String endpoint) async {
    final response = await http.delete(Uri.parse(BASE_URL + endpoint), headers: {
      "Authorization": AUTH_TOKEN
    });

    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> postFile(String endpoint, File file) async {
    final request = http.MultipartRequest("POST", Uri.parse(BASE_URL + endpoint));
    request.headers["Authorization"] = AUTH_TOKEN;
    request.files.add(http.MultipartFile.fromBytes("file", await file.readAsBytes(), filename: file.path.split("/").last));
    final response = await request.send();
    
    return json.decode(await response.stream.bytesToString());
  }
}