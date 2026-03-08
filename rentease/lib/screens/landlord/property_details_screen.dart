import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentease/models/property_model.dart';
import 'package:rentease/models/room_model.dart';
import 'package:rentease/models/user_model.dart';
import 'package:rentease/screens/chat/chat_screen.dart';
import 'package:rentease/screens/landlord/assign_tenant_form.dart'; 
import 'package:rentease/screens/landlord/log_payment_form.dart';
import 'package:rentease/services/chat_service.dart';
import 'package:rentease/services/property_service.dart';
import 'package:rentease/services/room_service.dart';
import 'package:rentease/utils/constants.dart';

class PropertyDetailsScreen extends StatefulWidget {
  final PropertyModel property;
  const PropertyDetailsScreen({super.key, required this.property});

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  bool _isLoading = false;

  void _refresh() {
    setState(() {});
  }

  void _showOccupiedRoomOptions(BuildContext context, RoomModel room) {
    final roomService = context.read<RoomService>();
    final chatService = context.read<ChatService>();
    final landlordId = context.read<UserModel?>()?.id;
    
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Log Rent Payment'),
              onTap: () {
                Navigator.of(ctx).pop();
                _showLogPaymentForm(context, room);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_remove),
              title: const Text('Remove Tenant from Room'),
              onTap: () {
                Navigator.of(ctx).pop();
                _showRemoveTenantConfirmation(context, roomService, room);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Chat with Tenant'),
              onTap: () async {
                Navigator.of(ctx).pop();
                if (landlordId == null || room.tenantId == null) return;
                try {
                  final chatRoom = await chatService.getOrCreateChatRoom(room.tenantId!, landlordId);
                  if (context.mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(chatRoom: chatRoom),
                      ),
                    );
                  }
                } catch (e) {
                   if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString()), backgroundColor: kErrorColor),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showRemoveTenantConfirmation(BuildContext context, RoomService roomService, RoomModel room) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Remove ${room.tenantName}?'),
          content: Text('Are you sure you want to remove ${room.tenantName} from Room ${room.roomNumber}? This will set the room to "vacant".'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kErrorColor),
              onPressed: () async {
                try {
                  await roomService.removeTenantFromRoom(room.id);
                  if (context.mounted) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tenant removed.'), backgroundColor: Colors.green),
                    );
                    _refresh();
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e'), backgroundColor: kErrorColor),
                    );
                  }
                }
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  void _showLogPaymentForm(BuildContext context, RoomModel room) {
    if (room.tenantId == null || room.tenantName == null) return;
    
    final tenant = UserModel(
      id: room.tenantId!,
      name: room.tenantName!,
      email: '',
      role: 'tenant',
    );
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LogPaymentForm(
          property: widget.property,
          tenants: [tenant],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final propertyService = context.read<PropertyService>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Delete ${widget.property.address}?'),
          content: const Text('Are you sure? This action is permanent and cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kErrorColor),
              onPressed: () async {
                setState(() { _isLoading = true; });
                try {
                  await propertyService.deleteProperty(widget.property.id);
                  if (context.mounted) {
                    Navigator.of(dialogContext).pop(); 
                    Navigator.of(context).pop(); 
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Property deleted'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete: $e'), backgroundColor: kErrorColor),
                    );
                  }
                }
                setState(() { _isLoading = false; });
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomService = context.read<RoomService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.property.address),
        actions: [
           IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Refresh Rooms',
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AssignTenantForm(property: widget.property),
                ),
              );
              _refresh();
            },
            tooltip: 'Assign New Tenant',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: Colors.red,
            onPressed: () => _showDeleteConfirmation(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Property Status',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatChip(title: 'Total Rooms', value: widget.property.totalRoomCount.toString()),
                    _StatChip(title: 'Occupied', value: widget.property.occupiedRoomsCount.toString()),
                    _StatChip(title: 'Available', value: widget.property.availableRoomCount.toString(), isHighlighted: true),
                  ],
                ),
                const Divider(height: 32),
                
                Text(
                  'Rooms',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Expanded(
                  // --- FIXED TO FUTURE BUILDER ---
                  child: FutureBuilder<List<RoomModel>>(
                    future: roomService.getRoomsForProperty(widget.property.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text(
                            'No rooms found.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        );
                      }
                      
                      final rooms = snapshot.data!;
                      return ListView.builder(
                        itemCount: rooms.length,
                        itemBuilder: (context, index) {
                          final room = rooms[index];
                          final isOccupied = room.status == 'occupied';
                          
                          return Card(
                            color: isOccupied ? Colors.white : kSecondaryColor,
                            margin: const EdgeInsets.symmetric(vertical: 6.0),
                            child: ListTile(
                              title: Text('Room ${room.roomNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                isOccupied
                                  ? 'Tenant: ${room.tenantName ?? "Unknown"}\nRent: R ${room.rentAmount.toStringAsFixed(2)}'
                                  : 'Status: Vacant\nType: ${room.roomType}',
                                style: TextStyle(color: isOccupied ? Colors.black87 : Colors.grey[700]),
                              ),
                              trailing: Icon(
                                isOccupied ? Icons.person : Icons.person_outline,
                                color: isOccupied ? kPrimaryColor : Colors.grey,
                              ),
                              onTap: isOccupied
                                ? () => _showOccupiedRoomOptions(context, room)
                                : null,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String title;
  final String value;
  final bool isHighlighted;

  const _StatChip({required this.title, required this.value, this.isHighlighted = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isHighlighted ? Colors.green[700] : kPrimaryColor,
          ),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }
}