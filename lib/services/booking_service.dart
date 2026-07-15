import 'dart:convert';
import '../core/const/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../models/booking.dart';
import 'api_response.dart';

class BookingService {
  static const String baseUrl = ApiEndpoints.booking;

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'x-user-id': '1',
  };

  static Future<List<Booking>> getBookings() async {
    final response = await apiClient.get(Uri.parse(baseUrl), headers: headers);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Booking.fromJson(e)).toList();
    } else {
      throw Exception('Không thể tải danh sách booking');
    }
  }

  static Future<bool> addBooking({
    required int userId,
    required String checkIn,
    required String checkOut,
    required int totalGuests,
    required List<int> roomIds,
    String? promotionCode,
  }) async {
    final response = await apiClient.post(
      Uri.parse(baseUrl),
      headers: headers,
      body: jsonEncode({
        'user_id': userId,
        'check_in': checkIn,
        'check_out': checkOut,
        'total_guests': totalGuests,
        'room_ids': roomIds,
        'promotion_code': promotionCode,
        'services': [],
      }),
    );

    return isSuccessfulStatus(response.statusCode);
  }

  static Future<bool> updateBooking({
    required int id,
    required String status,
    required String checkIn,
    required String checkOut,
  }) async {
    final response = await apiClient.put(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
      body: jsonEncode({
        'status': status,
        'check_in': checkIn,
        'check_out': checkOut,
      }),
    );

    return isSuccessfulStatus(response.statusCode);
  }

  static Future<bool> deleteBooking(int id) async {
    final response = await apiClient.delete(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
    );

    return isSuccessfulStatus(response.statusCode);
  }
}
