import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rentease/models/property_model.dart';
import 'package:rentease/models/user_model.dart';
import 'package:rentease/services/property_service.dart';
import 'package:rentease/utils/constants.dart';
import 'package:rentease/widgets/custom_button.dart';

class PropertyForm extends StatefulWidget {
  // Editing is more complex now, so we'll just support creating for now
  // final PropertyModel? property; 
  const PropertyForm({super.key});

  @override
  State<PropertyForm> createState() => _PropertyFormState();
}

class _PropertyFormState extends State<PropertyForm> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _singleCountController = TextEditingController(text: '0');
  final _sharingCountController = TextEditingController(text: '0');
  final _bachelorCountController = TextEditingController(text: '0');
  bool _isLoading = false;

  @override
  void dispose() {
    _addressController.dispose();
    _singleCountController.dispose();
    _sharingCountController.dispose();
    _bachelorCountController.dispose();
    super.dispose();
  }

  Future<void> _saveProperty() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() { _isLoading = true; });

    final user = context.read<UserModel?>();
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User not found')),
      );
      setState(() { _isLoading = false; });
      return;
    }

    try {
      final propertyService = context.read<PropertyService>();
      final property = PropertyModel(
        // We pass dummy values for the 'view' fields,
        // as they won't be saved to the DB.
        id: '', 
        landlordId: user.id,
        address: _addressController.text.trim(),
        roomCountSingle: int.tryParse(_singleCountController.text) ?? 0,
        roomCountSharing: int.tryParse(_sharingCountController.text) ?? 0,
        roomCountBachelor: int.tryParse(_bachelorCountController.text) ?? 0,
        occupiedRoomsCount: 0,
        totalRoomCount: 0,
        availableRoomCount: 0,
        calculatedStatus: 'vacant',
      );

      // Add new property
      await propertyService.addProperty(property);
      
      if(mounted) {
        Navigator.of(context).pop();
      }

    } catch (e) {
      if(mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save property: $e'), backgroundColor: kErrorColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Property'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Property Address'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text('Total Room Counts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _singleCountController,
                decoration: const InputDecoration(labelText: 'Single Rooms'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sharingCountController,
                decoration: const InputDecoration(labelText: 'Sharing Rooms'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bachelorCountController,
                decoration: const InputDecoration(labelText: 'Bachelor Rooms'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : CustomButton(
                      text: 'Save Property',
                      onPressed: _saveProperty,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}