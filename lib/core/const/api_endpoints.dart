class ApiEndpoints {
  static const String unsplashBaseUrl = "https://api.unsplash.com";
  static const String clientId = "3uOtwyvGgTxcSq5xkqOfIf-JwJqqpJQD7BO-HV7_DDE";
  static const String unsplashRooms =
      "$unsplashBaseUrl/search/photos/?client_id=$clientId&query=room&per_page=30";
  static const String baseUrl = "http://143.198.221.127/api";
  static const String customer = "$baseUrl/customer";
  static const String customerUpdatePassword = "$customer/update-password";
  static const String room = "$baseUrl/rooms";

  static String customerByEmail(String email) => "$customer/email/$email";
  static String customerById(String id) => "$customer/$id";
}
