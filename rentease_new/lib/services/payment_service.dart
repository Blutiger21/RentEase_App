import 'package:flutter/foundation.dart';
import 'package:rentease/models/payment_model.dart';
import 'package:rentease/services/storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentService {
  final SupabaseClient _client;
  late final StorageService _storageService;

  PaymentService(this._client) {
    _storageService = StorageService(_client.storage);
  }

  // ... (logPayment, approvePayment, rejectPayment, submitProofOfPayment are unchanged) ...
  Future<void> logPayment(PaymentModel payment) async {
    try {
      await _client.from('payments').insert(payment.toJson());
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }
  Future<void> approvePayment(String paymentId) async {
    try {
      await _client
          .from('payments')
          .update({'status': 'paid', 'pop_notes': null})
          .eq('id', paymentId);
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }
  Future<void> rejectPayment(String paymentId, String notes) async {
    try {
      await _client
          .from('payments')
          .update({'status': 'rejected', 'pop_notes': notes})
          .eq('id', paymentId);
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }
  Future<void> submitProofOfPayment(
    String paymentId,
    String tenantId,
    Uint8List imageBytes,
    String originalFileName,
    String? mimeType,
  ) async {
    try {
      final imageUrl = await _storageService.uploadProofOfPayment(
        imageBytes,
        tenantId,
        originalFileName,
        mimeType,
      );
      if (imageUrl == null) {
        throw Exception('Failed to upload proof of payment.');
      }
      await _client.from('payments').update({
        'pop_image_url': imageUrl,
        'status': 'pending_review',
        'pop_notes': null,
      }).eq('id', paymentId);
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }


  // --- SHARED ACTIONS (NOW USING FUTURE) ---

  // 5. Get payments for a Landlord
  Future<List<PaymentModel>> getPaymentsForLandlord(String landlordId) async {
    const String query = '*, tenant:users!payments_tenant_id_fkey(name)';
    
    // --- THIS IS THE FIX ---
    // Changed from Stream to Future. We just .select() and then await the result.
    final data = await _client
        .from('payments')
        .select(query)
        .eq('landlord_id', landlordId)
        .order('due_date', ascending: false);
    
    return (data as List).map((map) => PaymentModel.fromJson(map)).toList();
    // -----------------------
  }

  // 6. Get payments for a Tenant
  Future<List<PaymentModel>> getPaymentsForTenant(String tenantId) async {
    const String query = '*, landlord:users!payments_landlord_id_fkey(name)';

    // --- THIS IS THE FIX ---
    // Changed from Stream to Future.
    final data = await _client
        .from('payments')
        .select(query)
        .eq('tenant_id', tenantId)
        .order('due_date', ascending: false);
        
    return (data as List).map((map) => PaymentModel.fromJson(map)).toList();
    // -----------------------
  }
}