class ApiEndpoints {
  static const String unsplashBaseUrl = "https://api.unsplash.com";
  static const String clientId = "3uOtwyvGgTxcSq5xkqOfIf-JwJqqpJQD7BO-HV7_DDE";
  static const String unsplashRooms =
      "$unsplashBaseUrl/search/photos/?client_id=$clientId&query=room&per_page=30";
  static const String baseUrl =
      "https://f8d6-2405-4802-9178-8880-3513-c791-3c94-d53a.ngrok-free.app/api";
  static const String customer = "$baseUrl/customers";
  static const String customerUpdatePassword = "$customer/update-password";
  static const String room = "$baseUrl/rooms";
  static const String roomTypes = "$baseUrl/room-types";
  static const String service = "$baseUrl/services";
  static const String booking = "$baseUrl/bookings";
  static const String invoice = "$baseUrl/invoices";
  static const String review = "$baseUrl/reviews";
  static const String report = "$baseUrl/reports";
  static const String promotion = "$baseUrl/promotions";
  static const String payment = "$baseUrl/payments";
  static const String customerLogin = "$customer/login";
  static String customerByEmail(String email) => "$customer/email/$email";
  static String customerById(String id) => "$customer/$id";
  static String promotionByCode(String code) => "$promotion/code/$code";
  static String paymentByBooking(int bookingId) =>
      "$payment/booking/$bookingId";
}
