import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentease/models/maintenance_model.dart';
import 'package:rentease/models/property_model.dart';
import 'package:rentease/models/user_model.dart';
import 'package:rentease/services/maintenance_service.dart';
import 'package:rentease/services/property_service.dart';
import 'package:rentease/widgets/maintenance_card.dart';

class LandlordMaintenanceScreen extends StatelessWidget {
  const LandlordMaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserModel?>();
    final propertyService = context.watch<PropertyService>();

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance Requests'),
        automaticallyImplyLeading: false,
      ),
      // --- THIS IS THE FIX ---
      // Changed StreamBuilder to FutureBuilder
      body: FutureBuilder<List<PropertyModel>>(
        future: propertyService.getPropertiesForLandlord(user.id),
        // -----------------------
        builder: (context, propertySnapshot) {
          if (propertySnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (propertySnapshot.hasError) {
            return Center(child: Text('Error loading properties: ${propertySnapshot.error}'));
          }
          if (!propertySnapshot.hasData || propertySnapshot.data!.isEmpty) {
            return const Center(child: Text('You have no properties, so no maintenance requests can be shown.'));
          }

          final propertyIds = propertySnapshot.data!.map((prop) => prop.id).toList();

          return MaintenanceList(propertyIds: propertyIds);
        },
      ),
    );
  }
}

class MaintenanceList extends StatelessWidget {
  final List<String> propertyIds;
  const MaintenanceList({super.key, required this.propertyIds});

  @override
  Widget build(BuildContext context) {
    final maintenanceService = context.watch<MaintenanceService>();

    return StreamBuilder<List<MaintenanceRequestModel>>(
      stream: maintenanceService.getRequestsForLandlord(propertyIds),
      builder: (context, requestSnapshot) {
        if (requestSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (requestSnapshot.hasError) {
          return Center(child: Text('Error loading requests: ${requestSnapshot.error}'));
        }
        if (!requestSnapshot.hasData || requestSnapshot.data!.isEmpty) {
          return const Center(child: Text('No maintenance requests found for your properties.'));
        }

        final requests = requestSnapshot.data!;
        
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return MaintenanceCard(
              request: request,
              userRole: 'landlord',
            );
          },
        );
      },
    );
  }
}