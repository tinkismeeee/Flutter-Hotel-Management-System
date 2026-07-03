class BookingServiceModel {
  final int serviceId;
  final String serviceCode;
  final String name;
  final String price;
  final bool availability;
  final String description;

  const BookingServiceModel({
    required this.serviceId,
    required this.serviceCode,
    required this.name,
    required this.price,
    required this.availability,
    required this.description,
  });

  factory BookingServiceModel.fromJson(Map<String, dynamic> json) {
    return BookingServiceModel(
      serviceId: int.tryParse(json['service_id']?.toString() ?? '') ?? 0,
      serviceCode: json['service_code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: json['price']?.toString() ?? '0',
      availability: json['availability'] == true,
      description: json['description']?.toString() ?? '',
    );
  }
}
