import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentease/models/maintenance_model.dart';
import 'package:rentease/models/property_model.dart';
import 'package:rentease/models/user_model.dart';
import 'package:rentease/screens/shared/settings_screen.dart';
import 'package:rentease/screens/tenant/maintenance_form.dart';
import 'package:rentease/screens/chat/chat_room_list_screen.dart';
import 'package:rentease/screens/tenant/rent_status_screen.dart'; 
import 'package:rentease/services/maintenance_service.dart';
import 'package:rentease/services/property_service.dart';
import 'package:rentease/utils/constants.dart';
import 'package:rentease/widgets/maintenance_card.dart';
import 'package:rentease/widgets/property_card.dart';

class TenantDashboard extends StatefulWidget {
  const TenantDashboard({super.key});

  @override
  State<TenantDashboard> createState() => _TenantDashboardState();
}

class _TenantDashboardState extends State<TenantDashboard> {
  int _selectedIndex = 0;
  List<PropertyModel> _tenantProperties = [];
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      const TenantHomeTab(),
      const RentStatusScreen(),
      const ChatRoomListScreen(),
      const SettingsScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Helper to load properties for the FAB
  void _loadProperties(String userId) async {
    final service = context.read<PropertyService>();
    final props = await service.getPropertiesForTenant(userId);
    if (mounted) {
      setState(() {
        _tenantProperties = props;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserModel?>();
    
    // Load properties once when user is available
    if (user != null && _tenantProperties.isEmpty) {
      _loadProperties(user.id);
    }
        
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Rent'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _selectedIndex == 0 
          ? FloatingActionButton.extended(
              onPressed: () {
                if(_tenantProperties.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('You are not assigned to any property yet.'), backgroundColor: kErrorColor),
                  );
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => MaintenanceForm(properties: _tenantProperties),
                  ),
                );
              },
              label: const Text('New Request'),
              icon: const Icon(Icons.build),
            )
          : null,
    );
  }
}

class TenantHomeTab extends StatelessWidget {
  const TenantHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserModel?>();
    final propertyService = context.watch<PropertyService>();
    final maintenanceService = context.watch<MaintenanceService>();

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${user.name}'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('My Property', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // --- UPDATED TO FUTURE BUILDER ---
            FutureBuilder<List<PropertyModel>>(
              future: propertyService.getPropertiesForTenant(user.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('You are not assigned to a property yet.'),
                    ),
                  );
                }
                final property = snapshot.data!.first;
                return PropertyCard(property: property, onTap: null);
              },
            ),
            
            const SizedBox(height: 24),
            const Text('My Maintenance Requests', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            StreamBuilder<List<MaintenanceRequestModel>>(
              stream: maintenanceService.getRequestsForTenant(user.id),
              builder: (context, snapshot) {
                 if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('You have no maintenance requests.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  );
                }
                final requests = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return MaintenanceCard(request: request, userRole: 'tenant');
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}