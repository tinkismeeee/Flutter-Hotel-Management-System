class UnsplashRoomModel {
  final String id;
  final String description;
  final UnsplashRoomUrls urls;

  const UnsplashRoomModel({
    required this.id,
    required this.description,
    required this.urls,
  });

  factory UnsplashRoomModel.fromJson(Map<String, dynamic> json) {
    return UnsplashRoomModel(
      id: json['id']?.toString() ?? '',
      description:
          (json['description'] ?? json['alt_description'])?.toString() ?? '',
      urls: UnsplashRoomUrls.fromJson(
        (json['urls'] as Map?)?.cast<String, dynamic>() ?? {},
      ),
    );
  }

  static List<UnsplashRoomModel> listFromJson(Map<String, dynamic> json) {
    final results = json['results'];
    if (results is! List) return [];

    return results
        .map((item) => UnsplashRoomModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

class UnsplashRoomUrls {
  final String raw;
  final String full;
  final String regular;
  final String small;
  final String thumb;

  const UnsplashRoomUrls({
    required this.raw,
    required this.full,
    required this.regular,
    required this.small,
    required this.thumb,
  });

  factory UnsplashRoomUrls.fromJson(Map<String, dynamic> json) {
    return UnsplashRoomUrls(
      raw: json['raw']?.toString() ?? '',
      full: json['full']?.toString() ?? '',
      regular: json['regular']?.toString() ?? '',
      small: json['small']?.toString() ?? '',
      thumb: json['thumb']?.toString() ?? '',
    );
  }
}
