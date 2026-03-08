import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentease/models/property_model.dart';
import 'package:rentease/models/user_model.dart';
import 'package:rentease/screens/landlord/landlord_maintenance_screen.dart';
import 'package:rentease/screens/landlord/landlord_payments_screen.dart';
import 'package:rentease/screens/landlord/property_details_screen.dart';
import 'package:rentease/screens/landlord/property_form.dart';
import 'package:rentease/screens/landlord/tenant_list.dart';
import 'package:rentease/screens/shared/settings_screen.dart';
import 'package:rentease/services/property_service.dart';
import 'package:rentease/widgets/property_card.dart';

class LandlordDashboard extends StatefulWidget {
  const LandlordDashboard({super.key});

  @override
  State<LandlordDashboard> createState() => _LandlordDashboardState();
}

class _LandlordDashboardState extends State<LandlordDashboard> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    LandlordHomeTab(),
    LandlordMaintenanceScreen(),
    TenantListScreen(),
    LandlordPaymentsScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Maintenance'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Tenants'),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Payments'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, 
      ),
    );
  }
}

class LandlordHomeTab extends StatefulWidget {
  const LandlordHomeTab({super.key});

  @override
  State<LandlordHomeTab> createState() => _LandlordHomeTabState();
}

class _LandlordHomeTabState extends State<LandlordHomeTab> {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserModel?>();
    final propertyService = context.watch<PropertyService>();

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${user.name}'),
        automaticallyImplyLeading: false,
        actions: [
          // Add Refresh button since we are not streaming anymore
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {}); // Rebuilds to fetch new data
            },
          )
        ],
      ),
      // --- UPDATED TO FUTURE BUILDER ---
      body: FutureBuilder<List<PropertyModel>>(
        future: propertyService.getPropertiesForLandlord(user.id),
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
                'You have no properties.\nClick the + button to add one.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final properties = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: properties.length,
            itemBuilder: (context, index) {
              final property = properties[index];
              return PropertyCard(
                property: property,
                onTap: () async {
                  // When returning from details, refresh the list
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PropertyDetailsScreen(property: property),
                    ),
                  );
                  setState(() {}); 
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const PropertyForm(),
            ),
          );
          setState(() {}); // Refresh list after adding
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}