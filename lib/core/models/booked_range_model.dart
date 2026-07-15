class BookedRangeModel {
  final DateTime checkIn;
  final DateTime checkOut;

  const BookedRangeModel({required this.checkIn, required this.checkOut});

  factory BookedRangeModel.fromJson(Map<String, dynamic> json) {
    return BookedRangeModel(
      checkIn: _parseDate(json['check_in']),
      checkOut: _parseDate(json['check_out']),
    );
  }

  bool contains(DateTime day) {
    final date = _dateOnly(day);
    return !date.isBefore(checkIn) && date.isBefore(checkOut);
  }

  bool overlaps(DateTime start, DateTime end) {
    return _dateOnly(start).isBefore(checkOut) &&
        _dateOnly(end).isAfter(checkIn);
  }
}

DateTime _parseDate(Object? value) {
  final text = value?.toString() ?? '';
  if (text.length < 10) {
    throw const FormatException('Invalid booked range date');
  }
  final parts = text.substring(0, 10).split('-');
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
