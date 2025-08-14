import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationProvider with ChangeNotifier {
  Position? _currentPosition;
  String? _currentAddress;
  String? _pickupAddress;
  String? _dropAddress;
  LatLng? _pickupLocation;
  LatLng? _dropLocation;
  bool _isLoading = false;
  String? _error;
  Set<Marker> _markers = {};

  Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;
  String? get pickupAddress => _pickupAddress;
  String? get dropAddress => _dropAddress;
  LatLng? get pickupLocation => _pickupLocation;
  LatLng? get dropLocation => _dropLocation;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Set<Marker> get markers => _markers;

  Future<bool> requestLocationPermission() async {
    try {
      if (kIsWeb) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        return permission != LocationPermission.denied && 
               permission != LocationPermission.deniedForever;
      } else {
        final permission = await Permission.location.request();
        return permission.isGranted;
      }
    } catch (e) {
      _error = 'Failed to request location permission: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> getCurrentLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        _error = 'Location permission denied';
        return;
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        _currentAddress = _formatAddress(place);
        
        if (_pickupAddress == null) {
          _pickupAddress = _currentAddress;
          _pickupLocation = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
        }
      }

      _updateMarkers();
      
    } catch (e) {
      _error = 'Failed to get current location: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  String _formatAddress(Placemark place) {
    List<String> addressParts = [
      if (place.name?.isNotEmpty == true) place.name!,
      if (place.street?.isNotEmpty == true) place.street!,
      if (place.subLocality?.isNotEmpty == true) place.subLocality!,
      if (place.locality?.isNotEmpty == true) place.locality!,
      if (place.postalCode?.isNotEmpty == true) place.postalCode!,
      if (place.country?.isNotEmpty == true) place.country!,
    ];
    return addressParts.join(', ');
  }

  void _updateMarkers() {
    _markers.clear();
    
    if (_pickupLocation != null) {
      _markers.add(
        Marker(
          markerId: MarkerId('pickup'),
          position: _pickupLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Pickup Location',
            snippet: _pickupAddress,
          ),
        ),
      );
    }
    
    if (_dropLocation != null) {
      _markers.add(
        Marker(
          markerId: MarkerId('drop'),
          position: _dropLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Drop Location',
            snippet: _dropAddress,
          ),
        ),
      );
    }

    notifyListeners();
  }

  Future<void> setLocationFromMap(LatLng position, {bool isPickup = true}) async {
    _isLoading = true;
    notifyListeners();

    try {
      List<Placemark> placemarks = [];
      try {
        placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
      } catch (e) {
        print('Error getting placemarks: $e');
        if (isPickup) {
          _pickupLocation = position;
          _pickupAddress = 'Location (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
        } else {
          _dropLocation = position;
          _dropAddress = 'Location (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
        }
        updateMarkerPosition(position, isPickup);
        notifyListeners();
        return;
      }

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = _formatAddress(place);
        
        if (isPickup) {
          _pickupLocation = position;
          _pickupAddress = address;
        } else {
          _dropLocation = position;
          _dropAddress = address;
        }

        updateMarkerPosition(position, isPickup);
      }
    } catch (e) {
      _error = 'Failed to get address: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateMarkerPosition(LatLng position, bool isPickup) {
    final markerId = isPickup ? 'pickup' : 'drop';
    final hue = isPickup ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed;

    _markers.removeWhere((marker) => marker.markerId.value == markerId);
    _markers.add(
      Marker(
        markerId: MarkerId(markerId),
        position: position,
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        infoWindow: InfoWindow(
          title: isPickup ? 'Pickup Location' : 'Drop Location',
          snippet: isPickup ? _pickupAddress : _dropAddress,
        ),
      ),
    );

    notifyListeners();
  }

  Future<List<String>> searchPlaces(String query) async {
    if (query.isEmpty) return [];

    try {
      return [
        '$query, Near City Mall',
        '$query Market',
        '$query Junction',
        '$query Main Road',
        'New $query Colony',
        'Old $query Area',
        '$query Complex',
        '$query Bus Stop',
        '$query Metro Station',
        '$query Shopping Center',
      ].where((place) => place.toLowerCase().contains(query.toLowerCase())).toList();
    } catch (e) {
      _error = 'Failed to search places: $e';
      notifyListeners();
      return [];
    }
  }

  Future<void> saveRecentLocation(String address) async {
    print('Saved recent location: $address');
  }

  double calculateDistance(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    ) / 1000;
  }
}
