import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';

class SimpleMapPicker extends StatefulWidget {
  final bool isPickup;
  final Function(String) onLocationSelected;

  const SimpleMapPicker({
    Key? key,
    required this.isPickup,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  _SimpleMapPickerState createState() => _SimpleMapPickerState();
}

class _SimpleMapPickerState extends State<SimpleMapPicker> {
  GoogleMapController? _mapController;
  String? _selectedAddress;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        final currentPosition = locationProvider.currentPosition;
        final initialPosition = currentPosition != null
            ? LatLng(currentPosition.latitude, currentPosition.longitude)
            : const LatLng(20.5937, 78.9629);

        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: initialPosition,
                zoom: 16,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
              markers: locationProvider.markers,
              onMapCreated: (controller) {
                _mapController = controller;
                if (locationProvider.markers.isEmpty) {
                  locationProvider.updateMarkerPosition(initialPosition, widget.isPickup);
                }
              },
              onCameraIdle: () {
                _updateAddressFromCenter();
              },
            ),

            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 20),
                  Icon(
                    Icons.location_pin,
                    size: 50,
                    color: widget.isPickup ? Colors.green : Colors.red,
                  ),
                ],
              ),
            ),

            if (_selectedAddress != null)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    _selectedAddress!,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),

            if (_isLoading)
              Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Getting location...'),
                      ],
                    ),
                  ),
                ),
              ),

            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: ElevatedButton(
                onPressed: () async {
                  if (_mapController != null) {
                    final LatLng center = await _mapController!.getVisibleRegion().then(
                      (bounds) => LatLng(
                        (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
                        (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
                      ),
                    );

                    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
                    await locationProvider.setLocationFromMap(center, isPickup: widget.isPickup);
                    
                    final address = widget.isPickup 
                        ? locationProvider.pickupAddress 
                        : locationProvider.dropAddress;
                        
                    if (address != null) {
                      widget.onLocationSelected(address);
                      Navigator.pop(context);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.isPickup ? Colors.green : Colors.red,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Confirm Location',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateAddressFromCenter() async {
    if (_mapController == null) return;

    setState(() => _isLoading = true);

    try {
      final LatLng center = await _mapController!.getVisibleRegion().then(
        (bounds) => LatLng(
          (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
          (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
        ),
      );

      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      await locationProvider.setLocationFromMap(center, isPickup: widget.isPickup);
      
      setState(() {
        _selectedAddress = widget.isPickup
            ? locationProvider.pickupAddress
            : locationProvider.dropAddress;
      });

    } catch (e) {
      print('Error updating address: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
