import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rentease/models/payment_model.dart';
import 'package:rentease/models/property_model.dart';
import 'package:rentease/models/user_model.dart';
import 'package:rentease/services/payment_service.dart';
import 'package:rentease/utils/constants.dart';
import 'package:rentease/widgets/custom_button.dart';

class LogPaymentForm extends StatefulWidget {
  final PropertyModel property;
  final List<UserModel> tenants;

  const LogPaymentForm({
    super.key,
    required this.property,
    required this.tenants,
  });

  @override
  State<LogPaymentForm> createState() => _LogPaymentFormState();
}

class _LogPaymentFormState extends State<LogPaymentForm> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController(text: '${DateFormat('MMMM').format(DateTime.now())} Rent');
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  String? _selectedTenantId;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // --- THIS IS THE FIX ---
    // We can't pre-fill rent amount from the property anymore.
    // _amountController.text = widget.property.rentAmount.toStringAsFixed(0);
    // -----------------------
    _dateController.text = DateFormat.yMd().format(_selectedDate);
    if (widget.tenants.isNotEmpty) {
      _selectedTenantId = widget.tenants.first.id;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat.yMd().format(_selectedDate);
      });
    }
  }

  Future<void> _submitLogPayment() async {
    if (!_formKey.currentState!.validate() || _selectedTenantId == null) {
      return;
    }

    setState(() { _isLoading = true; });

    final landlord = context.read<UserModel?>();
    final paymentService = context.read<PaymentService>();

    if (landlord == null) {
      setState(() { _isLoading = false; });
      return;
    }

    final payment = PaymentModel(
      landlordId: landlord.id,
      tenantId: _selectedTenantId!,
      propertyId: widget.property.id,
      description: _descriptionController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      dueDate: _selectedDate,
      status: 'pending',
    );

    try {
      await paymentService.logPayment(payment);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment logged successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to log payment: $e'), backgroundColor: kErrorColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log New Rent Payment'),
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
                  DropdownButtonFormField<String>(
                    value: _selectedTenantId,
                    decoration: const InputDecoration(labelText: 'Select Tenant'),
                    items: widget.tenants.map((tenant) {
                      return DropdownMenuItem(
                        value: tenant.id,
                        child: Text(tenant.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedTenantId = value;
                      });
                    },
                    validator: (value) => value == null ? 'Please select a tenant' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description (e.g., November Rent)'),
                    validator: (value) => value!.isEmpty ? 'Please enter a description' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(labelText: 'Amount Due'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty || double.tryParse(value) == null) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dateController,
                    decoration: const InputDecoration(
                      labelText: 'Due Date',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context),
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    text: 'Log Payment',
                    onPressed: _submitLogPayment,
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            // --- FIX for deprecated 'withOpacity' ---
            Container(
              color: Colors.black54, 
              child: const Center(child: CircularProgressIndicator()),
            ),
            // ----------------------------------------
        ],
      ),
    );
  }
}