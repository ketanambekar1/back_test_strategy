import 'package:back_test_strategy/constants/api_constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json', 'Authorization': ApiConstants.bearerToken, 'Access-Control-Allow-Origin': '*'},
    ),
  );

  Future<Response?> getRequest(String endpoint) async {
    try {
      final response = await _dio.get(endpoint);
      return response;
    } on DioException catch (e) {
      if (e.response != null) {
        if (kDebugMode) {
          print('❌ API Error: ${e.response?.statusCode}');
          print('Response: ${e.response?.data}');
        }
      } else {
        if (kDebugMode) {
          print('⚠️ Request Error: ${e.message}');
        }
      }
      rethrow;
    }
  }
}
