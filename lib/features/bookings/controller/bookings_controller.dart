import 'dart:convert';

import '../../../core/const/api_endpoints.dart';
import '../../../core/models/user_booking_model.dart';
import '../../../core/network/api_client.dart';

class BookingsController {
  Future<List<UserBookingModel>> fetchBookings(int userId) async {
    final response = await apiClient.get(
      Uri.parse(ApiEndpoints.bookingsByUser(userId)),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load bookings');
    }

    final jsonData = json.decode(response.body);
    if (jsonData is! List) throw Exception('Invalid bookings response');

    return jsonData
        .whereType<Map<String, dynamic>>()
        .map(UserBookingModel.fromJson)
        .toList();
  }
}
