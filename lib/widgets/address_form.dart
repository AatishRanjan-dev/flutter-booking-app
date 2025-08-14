import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';

class AddressForm extends StatefulWidget {
  final bool isPickup;
  final Function(Map<String, String>) onAddressSubmit;

  const AddressForm({
    Key? key,
    required this.isPickup,
    required this.onAddressSubmit,
  }) : super(key: key);

  @override
  _AddressFormState createState() => _AddressFormState();
}

class _AddressFormState extends State<AddressForm> {
  final _formKey = GlobalKey<FormState>();
  final _streetController = TextEditingController();
  final _localityController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pinCodeController = TextEditingController();
  final _landmarkController = TextEditingController();

  @override
  void dispose() {
    _streetController.dispose();
    _localityController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinCodeController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final address = {
        'street': _streetController.text,
        'locality': _localityController.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'pinCode': _pinCodeController.text,
        'landmark': _landmarkController.text,
      };
      widget.onAddressSubmit(address);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _streetController,
            decoration: InputDecoration(
              labelText: 'Street Address / House No.',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value?.isEmpty == true ? 'Please enter street address' : null,
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _localityController,
            decoration: InputDecoration(
              labelText: 'Area / Locality',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value?.isEmpty == true ? 'Please enter locality' : null,
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    labelText: 'City',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty == true ? 'Please enter city' : null,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _stateController,
                  decoration: InputDecoration(
                    labelText: 'State',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty == true ? 'Please enter state' : null,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _pinCodeController,
                  decoration: InputDecoration(
                    labelText: 'PIN Code',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty == true ? 'Please enter PIN code' : null,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _landmarkController,
                  decoration: InputDecoration(
                    labelText: 'Landmark (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isPickup ? Colors.green : Colors.red,
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              'Confirm Address',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
