import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> callGCF(Map<String, dynamic> data) async {
  final response = await http.post(
    Uri.parse('http://127.0.0.1:5001/aipodclips-8369c/us-central1/api'),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode(data),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  } else {
    throw Exception('Failed to call GCF: ${response.statusCode}');
  }
}
