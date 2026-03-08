import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentease/models/payment_model.dart';
import 'package:rentease/models/user_model.dart';
import 'package:rentease/screens/landlord/payment_review_screen.dart';
import 'package:rentease/services/payment_service.dart';
import 'package:rentease/widgets/payment_card.dart';

class LandlordPaymentsScreen extends StatelessWidget {
  const LandlordPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserModel?>();
    final paymentService = context.watch<PaymentService>();

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        automaticallyImplyLeading: false,
      ),
      // --- THIS IS THE FIX ---
      // Changed from StreamBuilder to FutureBuilder
      body: FutureBuilder<List<PaymentModel>>(
        future: paymentService.getPaymentsForLandlord(user.id),
        // -----------------------
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
                'You have not logged any payments.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final payments = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              return PaymentCard(
                payment: payment,
                userRole: 'landlord',
                onCardTapped: () { 
                  if (payment.status == 'pending_review' || payment.popImageUrl != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PaymentReviewScreen(payment: payment),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}