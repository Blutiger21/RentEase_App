import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StatsService {
  final SupabaseClient _client;
  StatsService(this._client);

  // This calls all your new functions at once
  Future<Map<String, int>> getGlobalStats() async {
    try {
      // We use 'rpc' to call database functions
      final List<dynamic> results = await Future.wait([
        _client.rpc('get_total_users_count'),
        _client.rpc('get_total_properties_count'),
        _client.rpc('get_pending_maintenance_count'),
      ]);

      return {
        'total_users': results[0] as int,
        'total_properties': results[1] as int,
        'pending_requests': results[2] as int,
      };
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }
}