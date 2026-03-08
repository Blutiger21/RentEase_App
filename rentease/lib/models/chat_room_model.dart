class ChatRoomModel {
  final String id;
  final String tenantId;
  final String landlordId;
  // We'll add this field in the app, it's not in the DB
  final String otherUserName; 

  ChatRoomModel({
    required this.id,
    required this.tenantId,
    required this.landlordId,
    required this.otherUserName,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json, String otherUserName) {
    return ChatRoomModel(
      id: json['id'],
      tenantId: json['tenant_id'],
      landlordId: json['landlord_id'],
      otherUserName: otherUserName,
    );
  }
}