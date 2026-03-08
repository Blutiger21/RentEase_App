import 'package:flutter/foundation.dart';
import 'package:rentease/models/room_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RoomService {
  final SupabaseClient _client;
  RoomService(this._client);

  // --- UPDATED: Returns Future with Explicit Join ---
  Future<List<RoomModel>> getRoomsForProperty(String propertyId) async {
    // We specify 'users!rooms_tenant_id_fkey' to tell Supabase 
    // we want the user linked via the 'tenant_id' column.
    // We alias it as 'tenant' to make the JSON cleaner.
    const String query = '*, tenant:users!rooms_tenant_id_fkey(name)'; 
    
    try {
      final data = await _client
          .from('rooms')
          .select(query)
          .eq('property_id', propertyId)
          .order('room_number', ascending: true);
          
      return (data as List).map((map) => RoomModel.fromJson(map)).toList();
    } catch (e) {
      debugPrint('Error fetching rooms: $e');
      return [];
    }
  }
  // --------------------------------------------------

  Future<void> assignTenantToNewRoom({
    required String propertyId,
    required String landlordId,
    required String tenantId,
    required String roomNumber,
    required String roomType,
    required double rentAmount,
  }) async {
    try {
      final room = RoomModel(
        id: '', 
        propertyId: propertyId,
        landlordId: landlordId,
        tenantId: tenantId,
        roomNumber: roomNumber,
        roomType: roomType,
        rentAmount: rentAmount,
        status: 'occupied',
        tenantName: null,
      );

      await _client.from('rooms').insert(room.toJson());
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  Future<void> assignTenantToVacantRoom({
    required String roomId,
    required String tenantId,
    required double rentAmount,
  }) async {
    try {
      await _client.from('rooms').update({
        'tenant_id': tenantId,
        'rent_amount': rentAmount,
        'status': 'occupied'
      }).eq('id', roomId);
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  Future<void> removeTenantFromRoom(String roomId) async {
    try {
      await _client.from('rooms').update({
        'tenant_id': null,
        'status': 'vacant'
      }).eq('id', roomId);
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }
}