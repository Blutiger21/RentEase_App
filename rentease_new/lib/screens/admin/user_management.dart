import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentease/models/user_model.dart';
import 'package:rentease/services/database_service.dart';
import 'package:rentease/widgets/tenant_card.dart'; // Re-using this widget
import 'package:rentease/utils/constants.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Note: We use context.watch so the screen rebuilds when the stream updates
    final dbService = context.watch<DatabaseService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: dbService.streamUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          final users = snapshot.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return TenantCard(
                // Using TenantCard as a generic user display
                user: user,
                onTap: () {
                  _showUserActions(context, user);
                },
              );
            },
          );
        },
      ),
    );
  }

  // ... (inside UserManagementScreen class)

  void _showUserActions(BuildContext context, UserModel user) {
    // Get the services BEFORE the dialog
    final dbService = context.read<DatabaseService>();
    final currentUser = context.read<UserModel?>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        // Prevent admin from deleting themselves
        final isSelf = (currentUser != null && currentUser.id == user.id);

        return AlertDialog(
          title: Text(user.name),
          content:
              Text('Role: ${user.role}\nEmail: ${user.email}\nID: ${user.id}'),
          actions: [
            TextButton(
              onPressed: isSelf
                  ? null
                  : () {
                      // Disable button if it's you
                      // --- ADD CONFIRMATION DIALOG ---
                      Navigator.of(dialogContext).pop(); // Close first dialog
                      _showDeleteConfirmation(context, dbService, user);
                    },
              child: Text(
                isSelf ? 'Cannot Delete Self' : 'Delete User',
                style: TextStyle(color: isSelf ? Colors.grey : Colors.red),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // --- ADD THIS NEW HELPER METHOD ---
  void _showDeleteConfirmation(
      BuildContext context, DatabaseService dbService, UserModel user) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Delete ${user.name}?'),
          content: const Text(
              'Are you sure? This action is permanent and cannot be undone. The user will be completely removed from the system.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kErrorColor),
              onPressed: () async {
                try {
                  await dbService.deleteUser(user.id);
                  if (context.mounted) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('User deleted successfully'),
                          backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Failed to delete user: $e'),
                          backgroundColor: kErrorColor),
                    );
                  }
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
