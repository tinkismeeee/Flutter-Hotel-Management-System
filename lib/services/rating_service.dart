import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/rating.dart';

class RatingService {
  static const String baseUrl = 'http://143.198.221.127:5678/api/reviews';

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'x-user-id': '1',
  };

  static Future<List<HotelRating>> getRatings() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final reviews = _extractReviewList(data);
      return reviews.map((e) => HotelRating.fromJson(e)).toList();
    }

    throw Exception('Không thể tải danh sách đánh giá');
  }

  static Future<bool> updateRating({
    required int id,
    required int rating,
    required String comment,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
      body: jsonEncode({'rating': rating, 'comment': comment}),
    );

    debugPrint('UPDATE RATING STATUS: ${response.statusCode}');
    debugPrint('UPDATE RATING BODY: ${response.body}');

    return response.statusCode == 200 || response.statusCode == 204;
  }

  static List<Map<String, dynamic>> _extractReviewList(dynamic data) {
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }

    if (data is Map<String, dynamic>) {
      for (final key in ['data', 'reviews', 'items', 'result']) {
        final value = data[key];
        if (value is List) {
          return value.whereType<Map<String, dynamic>>().toList();
        }
      }
    }

    return [];
  }
}
