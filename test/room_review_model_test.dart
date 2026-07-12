import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_system_management/core/models/room_review_model.dart';

void main() {
  test('parses room review and builds reviewer name', () {
    final review = RoomReviewModel.fromJson({
      'review_id': 4,
      'booking_id': 4,
      'user_id': 19,
      'room_id': 11,
      'rating': 4,
      'comment': 'Great stay',
      'created_at': '2026-07-11T20:47:23.443Z',
      'username': 'thu.dinh',
      'first_name': 'Thu',
      'last_name': 'Dinh',
    });

    expect(review.roomId, 11);
    expect(review.rating, 4);
    expect(review.reviewerName, 'Thu Dinh');
    expect(review.createdAt, isNotNull);
  });
}
