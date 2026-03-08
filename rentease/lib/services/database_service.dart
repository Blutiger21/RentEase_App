// THIS IMPORT FIXES THE ERROR
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rentease/models/user_model.dart';
import 'package:flutter/material.dart'; // For debugPrint
import 'package:flutter/foundation.dart';

class DatabaseService {
  final SupabaseClient _client;
  DatabaseService(this._client);

  Future<UserModel?> getUserData(String id) async {
    try {
      final data = await _client.from('users').select().eq('id', id).single();

      return UserModel.fromJson(data);
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  Stream<List<UserModel>> streamUsers() {
    // THIS 'map' IS ON A STREAM, NOT A FUTURE, WHICH IS CORRECT
    return _client.from('users').stream(primaryKey: ['id']).map((listOfMaps) {
      return listOfMaps.map((map) => UserModel.fromJson(map)).toList();
    });
  }

  // ... (inside the DatabaseService class)

  Future<UserModel?> findUserByEmail(String email) async {
    try {
      final data = await _client
          .from('users')
          .select()
          .eq('email', email)
          .eq('role', 'tenant') // Ensure we only find tenants
          .single(); // .single() will error if 0 or 2+ users are found
      return UserModel.fromJson(data);
    } catch (e) {
      debugPrint("Error finding user by email: ${e.toString()}");
      return null;
    }
  }

  // ... (inside DatabaseService class, after streamUsers)

  Future<List<UserModel>> getUsersFromList(List<String> userIds) async {
    try {
      if (userIds.isEmpty) {
        return [];
      }

      // Use PostgREST 'in' operator via .filter to find all users whose ID is in the list
      final inArg = '(${userIds.map((id) => '"$id"').join(",")})';
      final data =
          await _client.from('users').select().filter('id', 'in', inArg);

      return (data as List).map((map) => UserModel.fromJson(map)).toList();
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  // ... (inside DatabaseService class)

  Future<void> deleteUser(String userId) async {
    try {
      // We use 'rpc' to call the database function
      await _client
          .rpc('delete_user_by_id', params: {'user_id_to_delete': userId});
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }
}
