import 'package:http/http.dart' as http;

class WebConnection {
  final String baseUrl;
  final String pushKey;

  WebConnection({this.baseUrl, this.pushKey});

  String _buildUrl(String method) {
    // Appending a slash if not set
    var url = baseUrl;
    if (!url.endsWith("/")) {
      url = url + "/";
    }

    // Appending the method and the push key
    return url + method + "?key=" + Uri.encodeQueryComponent(pushKey);
  }

  Future<http.Response> post(String method, {dynamic body}) async {
    return await http.post(_buildUrl(method), body: body);
  }
}
