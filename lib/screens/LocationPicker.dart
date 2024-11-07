import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationPicker extends StatefulWidget {
  final Function(double latitude, double longitude) onLocationPicked;

  const LocationPicker({super.key, required this.onLocationPicked});

  @override
  _LocationPickerState createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  late GoogleMapController mapController;
  LatLng _selectedPosition = const LatLng(0.0, 0.0);
  bool _isLocationSelected = false;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _onTap(LatLng position) {
    setState(() {
      _selectedPosition = position;
      _isLocationSelected = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Location')),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _selectedPosition,
              zoom: 15.0,
            ),
            onTap: _onTap,
            markers: _isLocationSelected
                ? {
                    Marker(
                      markerId: const MarkerId('selected-location'),
                      position: _selectedPosition,
                    ),
                  }
                : {},
          ),
          if (_isLocationSelected)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: ElevatedButton(
                onPressed: () {
                  widget.onLocationPicked(
                    _selectedPosition.latitude,
                    _selectedPosition.longitude,
                  );
                  Navigator.pop(context);
                },
                child: const Text('Confirm Location'),
              ),
            ),
        ],
      ),
    );
  }
}
