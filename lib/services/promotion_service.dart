import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/promotion.dart';

class PromotionService {
  static const String baseUrl = 'http://143.198.221.127/api/Promotions';

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'x-user-id': '1',
  };

  static Future<List<Promotion>> getPromotions() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Promotion.fromJson(e)).toList();
    }

    throw Exception('Không thể tải danh sách mã giảm giá');
  }

  static Future<bool> addPromotion({
    required String promotionCode,
    required String name,
    required double discountValue,
    required String startDate,
    required String endDate,
    required String scope,
    required String description,
    required bool isActive,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: headers,
      body: jsonEncode({
        'promotion_code': promotionCode,
        'name': name,
        'discount_value': discountValue,
        'start_date': startDate,
        'end_date': endDate,
        'scope': scope,
        'description': description,
        'is_active': isActive,
      }),
    );

    debugPrint('ADD PROMOTION STATUS: ${response.statusCode}');
    debugPrint('ADD PROMOTION BODY: ${response.body}');

    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<bool> updatePromotion({
    required int id,
    required String name,
    required double discountValue,
    required String startDate,
    required String endDate,
    required String scope,
    required String description,
    required bool isActive,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
      body: jsonEncode({
        'name': name,
        'discount_value': discountValue,
        'start_date': startDate,
        'end_date': endDate,
        'scope': scope,
        'description': description,
        'is_active': isActive,
      }),
    );

    debugPrint('UPDATE PROMOTION STATUS: ${response.statusCode}');
    debugPrint('UPDATE PROMOTION BODY: ${response.body}');

    return response.statusCode == 200;
  }

  static Future<bool> deletePromotion(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
    );

    debugPrint('DELETE PROMOTION STATUS: ${response.statusCode}');
    debugPrint('DELETE PROMOTION BODY: ${response.body}');

    return response.statusCode == 200 || response.statusCode == 204;
  }
}
