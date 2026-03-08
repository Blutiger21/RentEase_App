import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentease/services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false, // Removes back button on dashboard
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                // The AuthWrapper in main.dart will listen for this
                // and automatically navigate to the LoginScreen.
                await authService.signOut();
              },
            ),
            // TODO: Add other settings like 'Change Password'
            ListTile(
              leading: const Icon(Icons.password),
              title: const Text('Change Password'),
              onTap: () {
                // TODO: Implement password reset email flow
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password reset flow pending')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}