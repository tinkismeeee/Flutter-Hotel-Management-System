class ApiEndpoints {
  static const String unsplashBaseUrl = "https://api.unsplash.com";
  static const String clientId = "3uOtwyvGgTxcSq5xkqOfIf-JwJqqpJQD7BO-HV7_DDE";
  static const String unsplashRooms =
      "$unsplashBaseUrl/search/photos/?client_id=$clientId&query=room&per_page=30";
  static const String baseUrl = String.fromEnvironment(
    "API_BASE_URL",
    defaultValue: "https://nationally-amused-horse.ngrok-free.app/api",
  );
  static const String otpBaseUrl = "http://52.221.235.126:3001";
  static const String sendOtp = "$otpBaseUrl/send-otp";
  static const String verifyOtp = "$otpBaseUrl/verify-otp";
  static const String customer = "$baseUrl/customers";
  static const String customerGoogleLogin = "$customer/google";
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
  static const String googleServerClientId = String.fromEnvironment(
    "GOOGLE_SERVER_CLIENT_ID",
    defaultValue:
        "786154844319-91n2dmsrvndd62d6gbbu7k7cu48vpkc1.apps.googleusercontent.com",
  );
  static String customerByEmail(String email) => "$customer/email/$email";
  static String customerById(String id) => "$customer/$id";
  static String customerIdCards(String id) => "$customer/$id/id-card";
  static String customerIdCardImage(String id, String side) =>
      "$customer/$id/id-card/$side";
  static String promotionByCode(String code) => "$promotion/code/$code";
  static String paymentByBooking(int bookingId) =>
      "$payment/booking/$bookingId";
  static String reviewsByRoom(int roomId) => "$review/room/$roomId";
  static Uri roomBookedRanges({
    required int roomId,
    required DateTime from,
    required DateTime to,
  }) {
    return Uri.parse(
      "$room/$roomId/booked-ranges",
    ).replace(queryParameters: {'from': _utcDate(from), 'to': _utcDate(to)});
  }

  static String reviewEligibility({
    required int userId,
    required int roomId,
    int? bookingId,
  }) =>
      "$review/eligibility?userId=$userId&roomId=$roomId"
      "${bookingId == null ? '' : '&bookingId=$bookingId'}";
  static String bookingsByUser(int userId) => "$booking/user/$userId";

  static String _utcDate(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day).toIso8601String();
  }
}
