import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_system_management/core/const/api_endpoints.dart';

void main() {
  test('all hotel APIs use the configured server', () {
    expect(ApiEndpoints.baseUrl, 'http://54.91.41.3:5000/api');
    expect(ApiEndpoints.room, '${ApiEndpoints.baseUrl}/rooms');
    expect(ApiEndpoints.roomTypes, '${ApiEndpoints.baseUrl}/room-types');
    expect(ApiEndpoints.customer, '${ApiEndpoints.baseUrl}/customers');
    expect(ApiEndpoints.booking, '${ApiEndpoints.baseUrl}/bookings');
    expect(ApiEndpoints.service, '${ApiEndpoints.baseUrl}/services');
    expect(ApiEndpoints.promotion, '${ApiEndpoints.baseUrl}/promotions');
    expect(ApiEndpoints.invoice, '${ApiEndpoints.baseUrl}/invoices');
    expect(ApiEndpoints.staff, '${ApiEndpoints.baseUrl}/staff');
    expect(ApiEndpoints.payment, '${ApiEndpoints.baseUrl}/payments');
  });
}
