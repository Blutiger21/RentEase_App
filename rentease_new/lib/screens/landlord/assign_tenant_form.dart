import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentease/models/property_model.dart';
import 'package:rentease/models/user_model.dart';
import 'package:rentease/services/database_service.dart';
import 'package:rentease/services/room_service.dart';
import 'package:rentease/utils/constants.dart';
import 'package:rentease/widgets/custom_button.dart';

class AssignTenantForm extends StatefulWidget {
  final PropertyModel property;
  const AssignTenantForm({super.key, required this.property});

  @override
  State<AssignTenantForm> createState() => _AssignTenantFormState();
}

class _AssignTenantFormState extends State<AssignTenantForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _roomNumberController = TextEditingController();
  final _rentAmountController = TextEditingController();
  String _selectedRoomType = 'single';
  UserModel? _foundTenant;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _roomNumberController.dispose();
    _rentAmountController.dispose();
    super.dispose();
  }

  Future<void> _searchTenant() async {
    if (_emailController.text.isEmpty) return;
    
    setState(() { _isLoading = true; });
    final dbService = context.read<DatabaseService>();
    final tenant = await dbService.findUserByEmail(_emailController.text.trim());
    
    if (tenant != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Found tenant: ${tenant.name}'), backgroundColor: Colors.green),
      );
      setState(() { _foundTenant = tenant; });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tenant found with that email.'), backgroundColor: kErrorColor),
      );
      setState(() { _foundTenant = null; });
    }
    setState(() { _isLoading = false; });
  }

  Future<void> _submitAssignment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_foundTenant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please search and find a tenant first.'), backgroundColor: kErrorColor),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final roomService = context.read<RoomService>();
      await roomService.assignTenantToNewRoom(
        propertyId: widget.property.id,
        // --- PASS THE LANDLORD ID HERE ---
        landlordId: widget.property.landlordId,
        // ---------------------------------
        tenantId: _foundTenant!.id,
        roomNumber: _roomNumberController.text.trim(),
        roomType: _selectedRoomType,
        rentAmount: double.parse(_rentAmountController.text.trim()),
      );

      if (mounted) {
        Navigator.of(context).pop(); 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tenant assigned to room successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: kErrorColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Tenant to Room'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Step 1: Find Tenant ---
                  const Text('Step 1: Find Tenant', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Tenant\'s Email',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _searchTenant,
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  if (_foundTenant != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('Found: ${_foundTenant!.name}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ),
                  
                  const Divider(height: 32),

                  // --- Step 2: Room Details ---
                  const Text('Step 2: Room Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _roomNumberController,
                    decoration: const InputDecoration(labelText: 'Room Number (e.g., "10A")'),
                    validator: (value) => value!.isEmpty ? 'Please enter a room number' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _rentAmountController,
                    decoration: const InputDecoration(labelText: 'Monthly Rent Amount'),
                    keyboardType: TextInputType.number,
                    validator: (value) => (value == null || double.tryParse(value) == null) ? 'Enter a valid amount' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedRoomType,
                    decoration: const InputDecoration(labelText: 'Room Type'),
                    items: ['single', 'sharing', 'bachelor'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value[0].toUpperCase() + value.substring(1)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRoomType = value!;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  CustomButton(
                    text: 'Assign Tenant',
                    onPressed: _submitAssignment,
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}