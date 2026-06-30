class Promotion {
  final int promotionId;
  final String promotionCode;
  final String name;
  final double discountValue;
  final String startDate;
  final String endDate;
  final bool isActive;
  final String scope;
  final String description;

  Promotion({
    required this.promotionId,
    required this.promotionCode,
    required this.name,
    required this.discountValue,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.scope,
    required this.description,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      promotionId: json['promotion_id'] ?? 0,
      promotionCode: json['promotion_code'] ?? '',
      name: json['name'] ?? '',
      discountValue: double.tryParse(json['discount_value'].toString()) ?? 0,
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      isActive: json['is_active'] ?? true,
      scope: json['scope'] ?? '',
      description: json['description'] ?? '',
    );
  }
}