import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rentease/models/payment_model.dart';
import 'package:rentease/services/payment_service.dart';
import 'package:rentease/utils/constants.dart';
import 'package:rentease/widgets/custom_button.dart';

class PaymentReviewScreen extends StatefulWidget {
  final PaymentModel payment;
  const PaymentReviewScreen({super.key, required this.payment});

  @override
  State<PaymentReviewScreen> createState() => _PaymentReviewScreenState();
}

class _PaymentReviewScreenState extends State<PaymentReviewScreen> {
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _approvePayment() async {
    setState(() { _isLoading = true; });
    try {
      final paymentService = context.read<PaymentService>();
      await paymentService.approvePayment(widget.payment.id!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment Approved!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve: $e'), backgroundColor: kErrorColor),
        );
      }
    }
  }

  void _showRejectDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reject Payment'),
          content: TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Reason for rejection',
              hintText: 'e.g., "Amount is incorrect"',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_notesController.text.isEmpty) {
                  return;
                }
                Navigator.of(dialogContext).pop(); // Close dialog
                await _rejectPayment(_notesController.text.trim());
              },
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _rejectPayment(String notes) async {
    setState(() { _isLoading = true; });
    try {
      final paymentService = context.read<PaymentService>();
      await paymentService.rejectPayment(widget.payment.id!, notes);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment Rejected!'), backgroundColor: Colors.orange),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject: $e'), backgroundColor: kErrorColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canTakeAction = widget.payment.status == 'pending_review';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Payment'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.payment.description,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  'Amount: R ${widget.payment.amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  'Due Date: ${DateFormat.yMMMd().format(widget.payment.dueDate)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                
                const Text(
                  'Proof of Payment:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                
                // --- The Image ---
                if (widget.payment.popImageUrl == null)
                  const Center(child: Text('No Proof of Payment uploaded.'))
                else
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.payment.popImageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 400,
                        loadingBuilder: (context, child, progress) {
                          // --- THIS IS THE FIX ---
                          return progress == null
                              ? child
                              : SizedBox(
                                  height: 400,
                                  child: const Center(child: CircularProgressIndicator()),
                                );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          // --- THIS IS THE FIX ---
                          return SizedBox(
                            height: 400,
                            child: const Center(child: Text('Could not load image.')),
                          );
                        },
                      ),
                    ),
                  ),
                
                const SizedBox(height: 24),

                // --- Action Buttons ---
                if (canTakeAction)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _showRejectDialog,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kErrorColor,
                            side: const BorderSide(color: kErrorColor),
                          ),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomButton(
                          text: 'Approve',
                          onPressed: _approvePayment,
                        ),
                      ),
                    ],
                  ),
                
                // --- Show status if no action can be taken ---
                if (!canTakeAction)
                  Center(
                    child: Text(
                      'This payment is ${widget.payment.status.toUpperCase()}. No action needed.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                    ),
                  ),

                const SizedBox(height: 40),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}