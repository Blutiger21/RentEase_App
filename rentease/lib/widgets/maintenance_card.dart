import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rentease/models/maintenance_model.dart';
import 'package:rentease/services/maintenance_service.dart';
import 'package:rentease/utils/constants.dart';

class MaintenanceCard extends StatelessWidget {
  final MaintenanceRequestModel request;
  final String userRole; // 'tenant' or 'landlord'
  
  const MaintenanceCard({
    super.key,
    required this.request,
    required this.userRole,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Updated dialog method
  void _showUpdateStatusDialog(BuildContext context) {
    // We use a stateful builder to manage the dialog's internal state
    String selectedStatus = request.status; 
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Use StatefulBuilder to allow the dialog's state to be updated
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Update Request Status'),
              content: DropdownButton<String>(
                value: selectedStatus,
                isExpanded: true,
                items: ['pending', 'in_progress', 'resolved'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value.toUpperCase()),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    // Update the dialog's state
                    setDialogState(() {
                      selectedStatus = newValue;
                    });
                  }
                },
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text('Update'),
                  onPressed: () async {
                    final maintenanceService = context.read<MaintenanceService>();
                    try {
                      // Use the locally selected status
                      await maintenanceService.updateRequestStatus(
                        request.id!,
                        selectedStatus,
                      );
                      if (context.mounted) {
                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Status updated!'), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to update: $e'), backgroundColor: kErrorColor),
                        );
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final submittedDate = DateFormat.yMMMd().format(request.submittedAt);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Submitted: $submittedDate',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(request.status).withAlpha(30),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    request.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(request.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              request.description,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (request.imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Image.network(
                  request.imageUrl!,
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    return progress == null ? child : const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 100,
                      width: 100,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    );
                  },
                ),
              ),
            // Button is shown to landlord if request is not resolved
            if(userRole == 'landlord' && request.status != 'resolved')
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        // Call the updated dialog method
                        _showUpdateStatusDialog(context);
                      },
                      child: const Text('Update Status'),
                    ),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }
}