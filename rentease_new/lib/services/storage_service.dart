import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final SupabaseStorageClient _storage;
  StorageService(this._storage);
  
  final Uuid _uuid = const Uuid();

  Future<String?> uploadMaintenanceImage(File imageFile, String tenantId) async {
    try {
      String fileId = _uuid.v4();
      // --- FIX FOR MAINTENANCE IMAGES AS WELL ---
      // The path should be *inside* the bucket, starting with the tenantId
      String path = '$tenantId/$fileId.jpg'; 
      // ------------------------------------------

      await _storage
          .from('maintenance_images')
          .upload(path, imageFile); // Use corrected path

      final String publicUrl = _storage
          .from('maintenance_images')
          .getPublicUrl(path); // Use corrected path
          
      return publicUrl;
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  // --- THIS METHOD IS NOW FIXED ---
  Future<String?> uploadProofOfPayment(
    Uint8List imageBytes,
    String tenantId,
    String originalFileName,
    String? mimeType,
  ) async {
    try {
      final fileExtension = originalFileName.split('.').last.toLowerCase();
      final fileId = const Uuid().v4();
      
      // --- THIS IS THE FIX ---
      // The path must start with the tenantId to match our RLS policy.
      // We remove the bucket name 'proof_of_payment' from here.
      final String path = '$tenantId/$fileId.$fileExtension';
      // -----------------------

      final String contentType = mimeType ?? 'image/$fileExtension';

      await _storage.from('proof_of_payment').uploadBinary(
            path, // Use the corrected path
            imageBytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: false,
            ),
          );

      final String publicUrl = _storage
          .from('proof_of_payment')
          .getPublicUrl(path); // Get URL for the corrected path
          
      return publicUrl;
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }
}