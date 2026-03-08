class PropertyModel {
  // Original columns
  final String id;
  final String landlordId;
  final String address;
  final int roomCountSingle;
  final int roomCountSharing;
  final int roomCountBachelor;

  // Calculated columns from the VIEW
  final int occupiedRoomsCount;
  final int totalRoomCount;
  final int availableRoomCount;
  final String calculatedStatus; // 'occupied' | 'vacant'

  PropertyModel({
    required this.id,
    required this.landlordId,
    required this.address,
    required this.roomCountSingle,
    required this.roomCountSharing,
    required this.roomCountBachelor,
    required this.occupiedRoomsCount,
    required this.totalRoomCount,
    required this.availableRoomCount,
    required this.calculatedStatus,
  });

  // For writing data (creating a property)
  Map<String, dynamic> toJson() {
    return {
      'landlord_id': landlordId,
      'address': address,
      'room_count_single': roomCountSingle,
      'room_count_sharing': roomCountSharing,
      'room_count_bachelor': roomCountBachelor,
    };
  }

  // For reading data (from the VIEW)
  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      id: json['id'],
      landlordId: json['landlord_id'],
      address: json['address'],
      roomCountSingle: (json['room_count_single'] as num).toInt(),
      roomCountSharing: (json['room_count_sharing'] as num).toInt(),
      roomCountBachelor: (json['room_count_bachelor'] as num).toInt(),
      
      // Read the calculated values
      occupiedRoomsCount: (json['occupied_rooms_count'] as num).toInt(),
      totalRoomCount: (json['total_room_count'] as num).toInt(),
      availableRoomCount: (json['available_room_count'] as num).toInt(),
      calculatedStatus: json['calculated_status'],
    );
  }
}