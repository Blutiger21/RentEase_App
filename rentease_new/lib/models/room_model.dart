class RoomModel {
  final String id;
  final String propertyId;
  final String? tenantId;
  final String landlordId;
  final String roomNumber;
  final String roomType;
  final double rentAmount;
  final String status;
  
  final String? tenantName;

  RoomModel({
    required this.id,
    required this.propertyId,
    this.tenantId,
    required this.landlordId,
    required this.roomNumber,
    required this.roomType,
    required this.rentAmount,
    required this.status,
    this.tenantName,
  });

  Map<String, dynamic> toJson() {
    return {
      'property_id': propertyId,
      'tenant_id': tenantId,
      'landlord_id': landlordId,
      'room_number': roomNumber,
      'room_type': roomType,
      'rent_amount': rentAmount,
      'status': status,
    };
  }
  
  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'],
      propertyId: json['property_id'],
      tenantId: json['tenant_id'],
      landlordId: json['landlord_id'],
      roomNumber: json['room_number'],
      roomType: json['room_type'],
      rentAmount: (json['rent_amount'] as num).toDouble(),
      status: json['status'],
      // --- THIS IS THE FIX ---
      // We will alias the join as 'tenant' in the query
      tenantName: json['tenant'] != null ? json['tenant']['name'] : null,
      // -----------------------
    );
  }
}