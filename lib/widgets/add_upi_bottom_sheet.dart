import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/upi_details.dart';
import '../services/upi_service.dart';

class AddUPIBottomSheet extends StatefulWidget {
  final Function(UPIDetails) onUPIAdded;

  const AddUPIBottomSheet({
    super.key,
    required this.onUPIAdded,
  });

  @override
  State<AddUPIBottomSheet> createState() => _AddUPIBottomSheetState();
}

class _AddUPIBottomSheetState extends State<AddUPIBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _upiIdController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _upiService = UPIService();
  bool _isDefault = false;
  bool _isLoading = false;
  bool _isVerifying = false;

  Future<void> _verifyUPIId() async {
    if (_upiIdController.text.isEmpty) return;

    setState(() {
      _isVerifying = true;
    });

    try {
      final isValid = await _upiService.verifyUPIId(_upiIdController.text);
      if (!mounted) return;

      if (!isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid UPI ID'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _handleAddUPI() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final upiDetails = UPIDetails(
        id: _upiService.generateUPIId(),
        upiId: _upiIdController.text,
        bankName: _bankNameController.text,
        accountNumber: _accountNumberController.text,
        isDefault: _isDefault,
      );

      await _upiService.addUPIAccount(upiDetails);
      if (mounted) {
        widget.onUPIAdded(upiDetails);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('UPI account added successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add UPI account'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24.0,
        right: 24.0,
        top: 24.0,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add UPI Account',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _upiIdController,
                decoration: InputDecoration(
                  labelText: 'UPI ID',
                  border: const OutlineInputBorder(),
                  suffixIcon: _isVerifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.check_circle_outline),
                          onPressed: _verifyUPIId,
                        ),
                ),
                validator: UPIDetails.validateUPIId,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bankNameController,
                decoration: const InputDecoration(
                  labelText: 'Bank Name',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _accountNumberController,
                decoration: const InputDecoration(
                  labelText: 'Account Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: UPIDetails.validateAccountNumber,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Set as default'),
                value: _isDefault,
                onChanged: (value) {
                  setState(() {
                    _isDefault = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleAddUPI,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Add UPI Account'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _upiIdController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }
}
