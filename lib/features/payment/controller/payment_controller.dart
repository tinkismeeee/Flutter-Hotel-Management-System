import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/const/api_endpoints.dart';
import '../../../core/models/booking_service_model.dart';
import '../../../core/models/payos_payment_model.dart';
import '../../../core/models/room_model.dart';
import '../../../core/models/user_model.dart';

class PaymentController {
  Future<PromotionModel> validatePromotion(String code) async {
    final response = await http.get(
      Uri.parse(ApiEndpoints.promotionByCode(Uri.encodeComponent(code.trim()))),
    );
    final data = _decodeMap(response.body);
    if (response.statusCode != 200) {
      throw Exception(_errorMessage(data, 'Invalid discount code'));
    }
    return PromotionModel.fromJson(data);
  }

  Future<PayOsPaymentModel> createPayment({
    required UserModel user,
    required RoomModel room,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
    required List<BookingServiceModel> services,
    String? promotionCode,
  }) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.booking),
      headers: const {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': int.tryParse(user.userId),
        'check_in': checkIn.toIso8601String(),
        'check_out': checkOut.toIso8601String(),
        'total_guests': guests,
        'room_ids': [room.roomId],
        if (promotionCode != null && promotionCode.isNotEmpty)
          'promotion_code': promotionCode,
        'services': services
            .map((service) => {'service_id': service.serviceId, 'quantity': 1})
            .toList(),
      }),
    );
    final data = _decodeMap(response.body);
    if (response.statusCode != 201) {
      throw Exception(_errorMessage(data, 'Cannot create payment'));
    }
    return PayOsPaymentModel.fromJson(data);
  }

  Future<PayOsPaymentModel> getPayment(int bookingId) async {
    final response = await http.get(
      Uri.parse(ApiEndpoints.paymentByBooking(bookingId)),
    );
    final data = _decodeMap(response.body);
    if (response.statusCode != 200) {
      throw Exception(_errorMessage(data, 'Cannot check payment status'));
    }
    return PayOsPaymentModel.fromJson(data);
  }
}

Map<String, dynamic> _decodeMap(String body) {
  final decoded = json.decode(body);
  if (decoded is Map<String, dynamic>) return decoded;
  throw Exception('Invalid server response');
}

String _errorMessage(Map<String, dynamic> data, String fallback) {
  return (data['error'] ?? data['message'])?.toString() ?? fallback;
}
