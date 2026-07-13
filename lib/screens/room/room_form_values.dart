class RoomFormValues {
  final int floor;
  final double pricePerNight;
  final int maxGuests;
  final int bedCount;

  const RoomFormValues({
    required this.floor,
    required this.pricePerNight,
    required this.maxGuests,
    required this.bedCount,
  });

  static RoomFormValues? tryParse({
    required String floor,
    required String pricePerNight,
    required String maxGuests,
    required String bedCount,
  }) {
    final parsedFloor = int.tryParse(floor);
    final parsedPrice = double.tryParse(pricePerNight);
    final parsedGuests = int.tryParse(maxGuests);
    final parsedBeds = int.tryParse(bedCount);

    if (parsedFloor == null ||
        parsedPrice == null ||
        parsedGuests == null ||
        parsedBeds == null ||
        parsedFloor < 0 ||
        parsedPrice <= 0 ||
        parsedGuests <= 0 ||
        parsedBeds <= 0) {
      return null;
    }

    return RoomFormValues(
      floor: parsedFloor,
      pricePerNight: parsedPrice,
      maxGuests: parsedGuests,
      bedCount: parsedBeds,
    );
  }
}
