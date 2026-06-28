import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/booking.dart';

class BookingService {
  static const String baseUrl = 'http://143.198.221.127/api/bookings';

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'x-user-id': '1',
  };

  static Future<List<Booking>> getBookings() async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: headers,
    );

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
    final response = await http.post(
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

    print('ADD BOOKING STATUS: ${response.statusCode}');
    print('ADD BOOKING BODY: ${response.body}');

    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<bool> updateBooking({
    required int id,
    required String status,
    required String checkIn,
    required String checkOut,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
      body: jsonEncode({
        'status': status,
        'check_in': checkIn,
        'check_out': checkOut,
      }),
    );

    print('UPDATE BOOKING STATUS: ${response.statusCode}');
    print('UPDATE BOOKING BODY: ${response.body}');

    return response.statusCode == 200;
  }

  static Future<bool> deleteBooking(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
    );

    print('DELETE BOOKING STATUS: ${response.statusCode}');
    print('DELETE BOOKING BODY: ${response.body}');

    return response.statusCode == 200 || response.statusCode == 204;
  }
}