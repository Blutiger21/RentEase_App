import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentease/models/user_model.dart';
import 'package:rentease/screens/chat/chat_screen.dart';
import 'package:rentease/services/chat_service.dart';
import 'package:rentease/services/database_service.dart';
import 'package:rentease/widgets/tenant_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // <-- Make sure this is imported

class TenantListScreen extends StatelessWidget {
  const TenantListScreen({super.key});

  // New function to get all tenants
  Future<List<UserModel>> _getAllTenants(BuildContext context) async {
    final user = context.read<UserModel?>();
    final dbService = context.read<DatabaseService>();
    
    if (user == null) return [];

    // 1. Get all property IDs for the landlord
    final properties = await context.read<SupabaseClient>()
        .from('properties_with_status')
        .select('id')
        .eq('landlord_id', user.id);
    
    final propertyIds = properties.map((p) => p['id'] as String).toList();
    if (propertyIds.isEmpty) return [];

    // 2. Get all occupied rooms for those properties
    // Use .filter with the 'in' operator since .in_ may not be available on this PostgrestFilterBuilder.
    // PostgREST expects a parenthesized list, and string IDs should be quoted.
    final rooms = await context.read<SupabaseClient>()
        .from('rooms')
        .select()
        .filter('property_id', 'in', '(${propertyIds.map((id) => '"$id"').join(",")})')
        .eq('status', 'occupied');

    // 3. Get all unique tenant IDs from those rooms
    final tenantIds = rooms.map((r) => r['tenant_id'] as String).toSet().toList();
    if (tenantIds.isEmpty) return [];

    // 4. Get the user models for those tenants
    return await dbService.getUsersFromList(tenantIds);
  }


  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserModel?>();

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Tenants'),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _getAllTenants(context), // <-- context is passed here
        builder: (context, tenantSnapshot) {
          if (tenantSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (tenantSnapshot.hasError) {
            return Center(child: Text('Error loading tenants: ${tenantSnapshot.error}'));
          }
          if (!tenantSnapshot.hasData || tenantSnapshot.data!.isEmpty) {
            return const Center(child: Text('No tenants are assigned to your properties.'));
          }

          final tenants = tenantSnapshot.data!;
          
          return ListView.builder(
            itemCount: tenants.length,
            itemBuilder: (context, index) {
              final tenant = tenants[index];
              return TenantCard(
                user: tenant,
                onTap: () {
                  _startChat(context, user.id, tenant.id); // <-- context is passed here
                },
              );
            },
          );
        },
      ),
    );
  }

  // Helper function to start a chat
  Future<void> _startChat(BuildContext context, String landlordId, String tenantId) async {
    final chatService = context.read<ChatService>();
    try {
      final room = await chatService.getOrCreateChatRoom(tenantId, landlordId);
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(chatRoom: room),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        // --- THIS IS THE FIX ---
        ScaffoldMessenger.of(context).showSnackBar( // Was 't(context)'
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
        // -----------------------
      }
    }
  }
}