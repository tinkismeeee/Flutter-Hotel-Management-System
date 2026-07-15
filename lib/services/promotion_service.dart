import 'dart:convert';
import '../core/const/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../models/promotion.dart';
import 'api_response.dart';

class PromotionService {
  static const String baseUrl = ApiEndpoints.promotion;

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'x-user-id': '1',
  };

  static Future<List<Promotion>> getPromotions() async {
    final response = await apiClient.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Promotion.fromJson(e)).toList();
    } else {
      throw Exception('Không thể tải danh sách khuyến mãi');
    }
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
    final response = await apiClient.post(
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

    return isSuccessfulStatus(response.statusCode);
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
    final response = await apiClient.put(
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

    return isSuccessfulStatus(response.statusCode);
  }

  static Future<bool> deletePromotion(int id) async {
    final response = await apiClient.delete(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
    );

    return isSuccessfulStatus(response.statusCode);
  }
}
