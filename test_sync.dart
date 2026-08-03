import 'dart:io';
import 'package:dio/dio.dart';

void main() async {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/notes'));
  try {
    print('Testing POST...');
    final response = await dio.post('', data: {
      "id": "test-id-999",
      "title": "test",
      "body": "test",
      "version": 1,
      "updatedAt": "2026-08-03T23:02:30.305369",
      "isDeleted": false
    });
    print('Status: ${response.statusCode}');
    print('Data: ${response.data}');
    print('Type of data: ${response.data.runtimeType}');
    print('Type of id: ${response.data['id'].runtimeType}');
  } catch (e) {
    print('Error: $e');
  }
}
