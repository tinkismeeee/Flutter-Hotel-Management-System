class HotelService {
  final int serviceId;
  final String serviceCode;
  final String name;
  final double price;
  final bool availability;
  final String description;

  HotelService({
    required this.serviceId,
    required this.serviceCode,
    required this.name,
    required this.price,
    required this.availability,
    required this.description,
  });

  factory HotelService.fromJson(Map<String, dynamic> json) {
    return HotelService(
      serviceId: json['service_id'] ?? 0,
      serviceCode: json['service_code'] ?? '',
      name: json['name'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0,
      availability: json['availability'] ?? true,
      description: json['description'] ?? '',
    );
  }
}