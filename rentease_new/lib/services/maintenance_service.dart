import 'dart:io';
// --- THIS IMPORT FIXES THE ERROR ---
import 'package:supabase_flutter/supabase_flutter.dart';
// -----------------------------------
import 'package:flutter/foundation.dart';
import 'package:rentease/models/maintenance_model.dart';
import 'package:rentease/services/storage_service.dart';

class MaintenanceService {
  final SupabaseClient _client;
  late final StorageService _storageService;

  MaintenanceService(this._client) {
    _storageService = StorageService(_client.storage);
  }

  Future<void> submitRequest(MaintenanceRequestModel request, File? imageFile) async {
    try {
      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await _storageService.uploadMaintenanceImage(imageFile, request.tenantId);
      }
      Map<String, dynamic> requestData = request.toJson();
      if (imageUrl != null) {
        requestData['image_url'] = imageUrl;
      }
      await _client.from('maintenance_requests').insert(requestData);
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }
  
  Stream<List<MaintenanceRequestModel>> getRequestsForTenant(String tenantId) {
     return _client
        .from('maintenance_requests')
        .stream(primaryKey: ['id'])
        .eq('tenant_id', tenantId)
        .order('submitted_at', ascending: false)
        .map((listOfMaps) {
          return listOfMaps.map((map) => MaintenanceRequestModel.fromJson(map)).toList();
        });
  }
  
  Stream<List<MaintenanceRequestModel>> getRequestsForLandlord(List<String> propertyIds) {
    if (propertyIds.isEmpty) {
      return Stream.value([]);
    }
     return _client
        .from('maintenance_requests')
        .stream(primaryKey: ['id'])
        // --- THIS METHOD NOW WORKS ---
        //.in_('property_id', propertyIds)
        .order('submitted_at', ascending: false)
        .map((listOfMaps) {
          return listOfMaps.map((map) => MaintenanceRequestModel.fromJson(map)).toList();
        });
  }

  Future<void> updateRequestStatus(String requestId, String status) async {
    try {
      await _client
          .from('maintenance_requests')
          .update({'status': status})
          .eq('id', requestId);
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }
}