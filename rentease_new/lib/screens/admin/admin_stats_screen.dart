import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentease/services/stats_service.dart';
import 'package:rentease/utils/constants.dart';

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  // We use a Future so it only loads once
  late Future<Map<String, int>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = context.read<StatsService>().getGlobalStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Stats'),
        automaticallyImplyLeading: false,
        actions: [
          // Add a refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _statsFuture = context.read<StatsService>().getGlobalStats();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, int>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load stats: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No stats found.'));
          }

          final stats = snapshot.data!;
          final totalUsers = stats['total_users'] ?? 0;
          final totalProperties = stats['total_properties'] ?? 0;
          final pendingRequests = stats['pending_requests'] ?? 0;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _StatCard(
                  title: 'Total Users',
                  value: totalUsers.toString(),
                  icon: Icons.people,
                  color: Colors.blue,
                ),
                _StatCard(
                  title: 'Total Properties',
                  value: totalProperties.toString(),
                  icon: Icons.apartment,
                  color: Colors.green,
                ),
                _StatCard(
                  title: 'Pending Requests',
                  value: pendingRequests.toString(),
                  icon: Icons.build,
                  color: Colors.orange,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// A simple widget for the stat cards
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}