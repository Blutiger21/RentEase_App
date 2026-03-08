import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rentease/models/payment_model.dart';
import 'package:rentease/utils/constants.dart';

class PaymentCard extends StatelessWidget {
  final PaymentModel payment;
  final String userRole; // 'tenant' or 'landlord'
  final VoidCallback? onUploadPOP;
  final VoidCallback? onCardTapped;

  const PaymentCard({
    super.key,
    required this.payment,
    required this.userRole,
    this.onUploadPOP,
    this.onCardTapped,
  });

  Color _getStatusColor(String status) {
    // ... (no change in this method)
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'pending_review':
        return Colors.blue;
      case 'paid':
        return Colors.green;
      case 'rejected':
        return kErrorColor;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    // ... (no change in this method)
    switch (status) {
      case 'pending':
        return Icons.hourglass_top_rounded;
      case 'pending_review':
        return Icons.rate_review_rounded;
      case 'paid':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(payment.status);
    final statusIcon = _getStatusIcon(payment.status);
    final isPending = payment.status == 'pending';
    final isRejected = payment.status == 'rejected';
    final isPendingReview = payment.status == 'pending_review';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: (isPending || isRejected || (isPendingReview && userRole == 'landlord'))
              ? statusColor
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: userRole == 'landlord' && (isPendingReview || payment.popImageUrl != null)
            ? onCardTapped
            : null,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    payment.description,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Row(
                      children: [
                        Icon(statusIcon, color: statusColor, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          payment.status.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // --- THIS IS THE FIX ---
              if (payment.tenantName != null) // Show Tenant name to Landlord
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'For: ${payment.tenantName}',
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[700], fontSize: 14),
                  ),
                ),
              if (payment.landlordName != null) // Show Landlord name to Tenant
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'From: ${payment.landlordName}',
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[700], fontSize: 14),
                  ),
                ),
              // -----------------------

              const SizedBox(height: 12),
              Text(
                'Amount Due: R ${payment.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kPrimaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Due Date: ${DateFormat.yMMMd().format(payment.dueDate)}',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              
              if (isRejected && payment.popNotes != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: kErrorColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kErrorColor.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Note:',
                        style: TextStyle(fontWeight: FontWeight.bold, color: kErrorColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        payment.popNotes!,
                        style: const TextStyle(color: kErrorColor),
                      ),
                    ],
                  ),
                ),

              if (userRole == 'tenant' && (isPending || isRejected))
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: onUploadPOP,
                      icon: const Icon(Icons.upload_file_rounded),
                      label: Text(isRejected ? 'Upload New POP' : 'Upload Proof of Payment'),
                    ),
                  ),
                ),

              if (userRole == 'landlord' && isPendingReview)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'NEEDS REVIEW - Tap to see details',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}