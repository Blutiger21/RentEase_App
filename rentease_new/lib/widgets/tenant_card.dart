import 'package:flutter/material.dart';
import 'package:rentease/models/user_model.dart';

class TenantCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;

  const TenantCard({
    super.key,
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    IconData roleIcon;
    switch (user.role) {
      case 'landlord':
        roleIcon = Icons.house_siding;
        break;
      case 'tenant':
        roleIcon = Icons.person;
        break;
      case 'admin':
        roleIcon = Icons.admin_panel_settings;
        break;
      default:
        roleIcon = Icons.question_mark;
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(50),
          child: Icon(roleIcon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(user.email),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}