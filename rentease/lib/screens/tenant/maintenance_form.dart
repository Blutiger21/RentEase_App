import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:rentease/models/maintenance_model.dart';
import 'package:rentease/models/property_model.dart';
import 'package:rentease/models/user_model.dart';
import 'package:rentease/services/maintenance_service.dart';
import 'package:rentease/utils/constants.dart';
import 'package:rentease/widgets/custom_button.dart';


class MaintenanceForm extends StatefulWidget {
  final List<PropertyModel> properties;
  const MaintenanceForm({super.key, required this.properties});

  @override
  State<MaintenanceForm> createState() => _MaintenanceFormState();
}

class _MaintenanceFormState extends State<MaintenanceForm> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String? _selectedPropertyId;
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.properties.isNotEmpty) {
      _selectedPropertyId = widget.properties.first.id; // Use Supabase ID
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate() || _selectedPropertyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields'), backgroundColor: kErrorColor),
      );
      return;
    }

    setState(() { _isLoading = true; });

    final user = context.read<UserModel?>();
    if (user == null) {
      setState(() { _isLoading = false; });
      return;
    }

    // Use DateTime.now() for Supabase
    final request = MaintenanceRequestModel(
      tenantId: user.id,
      propertyId: _selectedPropertyId!,
      description: _descriptionController.text.trim(),
      status: 'pending',
      submittedAt: DateTime.now(),
    );

    try {
      final maintenanceService = context.read<MaintenanceService>();
      await maintenanceService.submitRequest(request, _imageFile);
      
      if(mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if(mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit request: $e'), backgroundColor: kErrorColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Maintenance Request'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedPropertyId,
                decoration: const InputDecoration(
                  labelText: 'Select Property',
                ),
                items: widget.properties.map((property) {
                  return DropdownMenuItem(
                    value: property.id, // Use Supabase ID
                    child: Text(property.address, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPropertyId = value;
                  });
                },
                validator: (value) => value == null ? 'Please select a property' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description of Issue'),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please describe the issue';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text('Add Photo (Optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Upload Image'),
              ),
              if (_imageFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Image.file(
                    _imageFile!,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : CustomButton(
                      text: 'Submit Request',
                      onPressed: _submitRequest,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}