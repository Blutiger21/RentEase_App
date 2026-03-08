class PaymentModel {
  final String? id;
  final String landlordId;
  final String tenantId;
  final String propertyId;
  final String description;
  final double amount;
  final DateTime dueDate;
  final String status; // 'pending' | 'pending_review' | 'paid' | 'rejected'
  final String? popImageUrl;
  final String? popNotes;
  
  // --- NEW FIELDS ---
  final String? tenantName;
  final String? landlordName;

  PaymentModel({
    this.id,
    required this.landlordId,
    required this.tenantId,
    required this.propertyId,
    required this.description,
    required this.amount,
    required this.dueDate,
    required this.status,
    this.popImageUrl,
    this.popNotes,
    this.tenantName,
    this.landlordName,
  });

  Map<String, dynamic> toJson() {
    // This doesn't change, as we don't write these names back
    return {
      'landlord_id': landlordId,
      'tenant_id': tenantId,
      'property_id': propertyId,
      'description': description,
      'amount': amount,
      'due_date': dueDate.toIso8601String(),
      'status': status,
      'pop_image_url': popImageUrl,
      'pop_notes': popNotes,
    };
  }

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'],
      landlordId: json['landlord_id'],
      tenantId: json['tenant_id'],
      propertyId: json['property_id'],
      description: json['description'] ?? '',
      amount: (json['amount'] as num).toDouble(),
      dueDate: DateTime.parse(json['due_date']),
      status: json['status'],
      popImageUrl: json['pop_image_url'],
      popNotes: json['pop_notes'],
      // --- THIS IS THE FIX ---
      // Check for the embedded 'tenant' or 'landlord' data
      tenantName: json['tenant'] != null ? json['tenant']['name'] : null,
      landlordName: json['landlord'] != null ? json['landlord']['name'] : null,
    );
  }
}