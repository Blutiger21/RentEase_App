import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentease/models/chat_room_model.dart';
import 'package:rentease/models/user_model.dart';
import 'package:rentease/screens/chat/chat_screen.dart';
import 'package:rentease/services/chat_service.dart';
import 'package:rentease/services/property_service.dart';

class ChatRoomListScreen extends StatelessWidget {
  const ChatRoomListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserModel?>();
    final chatService = context.watch<ChatService>();

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<ChatRoomModel>>(
        stream: chatService.getChatRooms(user.id, user.role),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  user.role == 'tenant'
                      ? 'You have no messages. Start a chat by finding your property on the Home tab.'
                      : 'You have no messages. A tenant must start a chat with you.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          final chatRooms = snapshot.data!;
          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final room = chatRooms[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(room.otherUserName.isNotEmpty ? room.otherUserName[0] : 'U'),
                ),
                title: Text(room.otherUserName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Tap to chat'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(chatRoom: room),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      // --- This button is only for Tenants to start a new chat ---
      floatingActionButton: user.role == 'tenant'
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.message),
              label: const Text('Chat with Landlord'),
              onPressed: () async {
                await _startChat(context, user.id);
              },
            )
          : null,
    );
  }

  // Helper method for tenant to find and start a chat
  Future<void> _startChat(BuildContext context, String tenantId) async {
    final propertyService = context.read<PropertyService>();
    final chatService = context.read<ChatService>();

    try {
      // 1. Find the tenant's property
      // --- THIS IS THE FIX ---
      // Removed .first because getPropertiesForTenant returns a Future List now
      final properties = await propertyService.getPropertiesForTenant(tenantId);
      // -----------------------
      
      if (properties.isEmpty) {
        throw Exception('You are not assigned to a property.');
      }
      final landlordId = properties.first.landlordId;

      // 2. Get or create the chat room
      final room = await chatService.getOrCreateChatRoom(tenantId, landlordId);

      // 3. Navigate to the chat screen
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(chatRoom: room),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }
}