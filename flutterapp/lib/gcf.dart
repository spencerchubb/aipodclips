import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

Future<Map<String, dynamic>> callGCF(Map<String, dynamic> data) async {
  debugPrint(data.toString());
  // final url = kDebugMode
  //     ? 'http://127.0.0.1:3000/api'
  //     : 'http://157.245.221.230:3000/api';
  // final url = 'http://157.245.221.230:3000/api';
  // final url = 'http://10.10.1.161:3000/api';
  final url = 'https://6733-69-212-112-109.ngrok-free.app/api';
  final response = await http.post(
    Uri.parse(url),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode(data),
  );

  if (response.statusCode == 200) {
    debugPrint(response.body);
    return jsonDecode(response.body) as Map<String, dynamic>;
  } else {
    throw Exception('Failed to call GCF: ${response.statusCode}');
  }
}
