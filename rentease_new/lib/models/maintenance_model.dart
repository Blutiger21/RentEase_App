class MaintenanceRequestModel {
  final String? id; // UUID from Supabase
  final String tenantId;
  final String propertyId;
  final String? roomNumber; // <-- ADD THIS
  final String description;
  final String? imageUrl;
  final String status; // 'pending' | 'in_progress' | 'resolved'
  final DateTime submittedAt;

  MaintenanceRequestModel({
    this.id,
    required this.tenantId,
    required this.propertyId,
    this.roomNumber, // <-- ADD THIS
    required this.description,
    this.imageUrl,
    required this.status,
    required this.submittedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'property_id': propertyId,
      'room_number': roomNumber, // <-- ADD THIS
      'description': description,
      'image_url': imageUrl,
      'status': status,
      'submitted_at': submittedAt.toIso8601String(),
    };
  }

  factory MaintenanceRequestModel.fromJson(Map<String, dynamic> json) {
    return MaintenanceRequestModel(
      id: json['id'],
      tenantId: json['tenant_id'],
      propertyId: json['property_id'],
      roomNumber: json['room_number'], // <-- ADD THIS
      description: json['description'],
      imageUrl: json['image_url'],
      status: json['status'],
      submittedAt: DateTime.parse(json['submitted_at']),
    );
  }
}