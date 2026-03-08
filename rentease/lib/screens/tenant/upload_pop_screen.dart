import 'dart:typed_data'; // <-- This is for the image bytes
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:rentease/models/payment_model.dart';
import 'package:rentease/models/user_model.dart';
import 'package:rentease/services/payment_service.dart';
import 'package:rentease/utils/constants.dart';
import 'package:rentease/widgets/custom_button.dart';

class UploadPopScreen extends StatefulWidget {
  final PaymentModel payment;
  const UploadPopScreen({super.key, required this.payment});

  @override
  State<UploadPopScreen> createState() => _UploadPopScreenState();
}

class _UploadPopScreenState extends State<UploadPopScreen> {
  // --- STATE VARIABLES UPDATED ---
  Uint8List? _imageBytes; // Store the image data
  XFile? _pickedFile; // Store the file info (for name and mimeType)
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _pickedFile = pickedFile; // Save the file info
      });
    }
  }

  Future<void> _submitPOP() async {
    if (_imageBytes == null || _pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first'), backgroundColor: kErrorColor),
      );
      return;
    }

    setState(() { _isLoading = true; });

    final user = context.read<UserModel?>();
    if (user == null) {
      setState(() { _isLoading = false; });
      return;
    }

    try {
      final paymentService = context.read<PaymentService>();
      
      // --- THIS IS THE FIX ---
      // We now pass the bytes, the file name, and the file's mimeType
      await paymentService.submitProofOfPayment(
        widget.payment.id!,
        user.id,
        _imageBytes!,
        _pickedFile!.name, 
        _pickedFile!.mimeType, // Pass the mimeType
      );
      // -----------------------

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proof of payment submitted for review!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e'), backgroundColor: kErrorColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Proof of Payment'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.payment.description,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  'Amount: R ${widget.payment.amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 32),
                
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _imageBytes == null
                      ? Center(
                          child: OutlinedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Select Image'),
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          // Use Image.memory (works on web and mobile)
                          child: Image.memory(
                            _imageBytes!,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
                if (_imageBytes != null)
                  TextButton(
                    onPressed: _pickImage,
                    child: const Text('Change Image'),
                  ),
                const SizedBox(height: 32),
                
                CustomButton(
                  text: 'Submit for Review',
                  onPressed: _submitPOP,
                ),
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