import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/const/api_endpoints.dart';
import '../../../core/models/room_model.dart';
import '../../../core/models/unsplash_room_model.dart';

class HomeData {
  final List<RoomModel> rooms;
  final List<UnsplashRoomModel> roomImages;

  const HomeData({required this.rooms, required this.roomImages});
}

class HomeController {
  Future<HomeData> fetchHomeData() async {
    final rooms = await fetchRooms();
    final roomImages = await fetchRoomImages();

    return HomeData(rooms: rooms, roomImages: roomImages);
  }

  Future<List<RoomModel>> fetchRooms() async {
    final response = await http.get(Uri.parse(ApiEndpoints.room));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch rooms: ${response.statusCode}');
    }

    final jsonData = json.decode(response.body);
    final roomsJson = switch (jsonData) {
      List<dynamic> data => data,
      {'data': List<dynamic> data} => data,
      _ => throw Exception('Invalid room response'),
    };

    return roomsJson
        .map((room) => RoomModel.fromJson(room as Map<String, dynamic>))
        .where((room) => room.isActive)
        .toList();
  }

  Future<List<UnsplashRoomModel>> fetchRoomImages() async {
    final response = await http.get(Uri.parse(ApiEndpoints.unsplashRooms));

    if (response.statusCode != 200) {
      return [];
    }

    final jsonData = json.decode(response.body) as Map<String, dynamic>;
    return UnsplashRoomModel.listFromJson(
      jsonData,
    ).where((image) => image.urls.regular.isNotEmpty).toList();
  }

  List<RoomModel> filterRooms(List<RoomModel> rooms, String type) {
    if (type == 'All') return rooms;
    return rooms.where((room) => room.roomTypeName == type).toList();
  }
}
