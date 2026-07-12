import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/const/api_endpoints.dart';
import '../../../core/models/booking_service_model.dart';
import '../../../core/models/payos_payment_model.dart';
import '../../../core/models/room_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/network/api_client.dart';

class PaymentController {
  Future<PromotionModel> validatePromotion(String code) async {
    debugPrint('[PAYOS][Flutter] promotion-check code=${code.trim()}');
    final response = await apiClient.get(
      Uri.parse(ApiEndpoints.promotionByCode(Uri.encodeComponent(code.trim()))),
    );
    final data = _decodeMap(response.body);
    if (response.statusCode != 200) {
      final message = _errorMessage(data, 'Invalid discount code');
      debugPrint(
        '[PAYOS][Flutter] promotion-rejected status=${response.statusCode} message="$message"',
      );
      throw Exception(message);
    }
    final promotion = PromotionModel.fromJson(data);
    debugPrint(
      '[PAYOS][Flutter] promotion-applied code=${promotion.code} discount=${promotion.discountValue}% scope=${promotion.scope}',
    );
    return promotion;
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
    debugPrint(
      '[PAYOS][Flutter] payment-create room=${room.roomId} user=${user.userId} guests=$guests '
      'checkIn=${checkIn.toIso8601String()} checkOut=${checkOut.toIso8601String()} '
      'services=${services.length} promotion=${promotionCode ?? 'none'}',
    );
    final response = await apiClient.post(
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
      final message = _errorMessage(data, 'Cannot create payment');
      debugPrint(
        '[PAYOS][Flutter] payment-create-failed status=${response.statusCode} message="$message"',
      );
      throw Exception(message);
    }
    final payment = PayOsPaymentModel.fromJson(data);
    debugPrint(
      '[PAYOS][Flutter] payment-created booking=${payment.bookingId} order=${payment.orderCode} '
      'amount=${payment.amount} status=${payment.status}',
    );
    return payment;
  }

  Future<PayOsPaymentModel> getPayment(int bookingId) async {
    debugPrint('[PAYOS][Flutter] payment-status-check booking=$bookingId');
    final response = await apiClient.get(
      Uri.parse(ApiEndpoints.paymentByBooking(bookingId)),
    );
    final data = _decodeMap(response.body);
    if (response.statusCode != 200) {
      final message = _errorMessage(data, 'Cannot check payment status');
      debugPrint(
        '[PAYOS][Flutter] payment-status-failed booking=$bookingId '
        'status=${response.statusCode} message="$message"',
      );
      throw Exception(message);
    }
    final payment = PayOsPaymentModel.fromJson(data);
    debugPrint(
      '[PAYOS][Flutter] payment-status-result booking=${payment.bookingId} '
      'order=${payment.orderCode} status=${payment.status}',
    );
    return payment;
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
