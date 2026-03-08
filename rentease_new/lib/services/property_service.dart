import 'package:flutter/foundation.dart';
import 'package:rentease/models/property_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PropertyService {
  final SupabaseClient _client;
  PropertyService(this._client);

  Future<void> addProperty(PropertyModel property) async {
    try {
      await _client.from('properties').insert(property.toJson());
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  Future<void> deleteProperty(String propertyId) async {
    try {
      await _client
          .from('properties')
          .delete()
          .eq('id', propertyId);
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  // --- UPDATED: Now returns a Future (Snapshot) ---
  Future<List<PropertyModel>> getPropertiesForLandlord(String landlordId) async {
    try {
      final data = await _client
          .from('properties_with_status') // Reading from the View
          .select()
          .eq('landlord_id', landlordId)
          .order('address', ascending: true);
          
      return (data as List).map((map) => PropertyModel.fromJson(map)).toList();
    } catch (e) {
      debugPrint(e.toString());
      return [];
    }
  }

  // --- UPDATED: Now returns a Future (Snapshot) ---
  Future<List<PropertyModel>> getPropertiesForTenant(String tenantId) async {
    try {
      final data = await _client
          .from('properties_with_status') // Reading from the View
          .select();
      // RLS policy ensures tenant only sees their assigned property
          
      return (data as List).map((map) => PropertyModel.fromJson(map)).toList();
    } catch (e) {
      debugPrint(e.toString());
      return [];
    }
  }
}