import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  final Function(LatLng) onLocationSelected;
  final LatLng? initialLocation;

  const MapPage({
    Key? key,
    required this.onLocationSelected,
    this.initialLocation,
  }) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller = Completer();
  final String _apiKey = 'AIzaSyDFYH2YvsVidC2ssabxM7ixKAMj6umhhK8';
  LatLng? _selectedLocation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      if (_selectedLocation == null) {
        final position = await Geolocator.getCurrentPosition();
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        actions: [
          if (_selectedLocation != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                widget.onLocationSelected(_selectedLocation!);
                Navigator.pop(context);
              },
            ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _selectedLocation ?? const LatLng(0, 0),
          zoom: 15,
        ),
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        onTap: (LatLng location) {
          setState(() {
            _selectedLocation = location;
          });
        },
        markers: _selectedLocation != null
            ? {
                Marker(
                  markerId: const MarkerId('selected_location'),
                  position: _selectedLocation!,
                ),
              }
            : {},
      ),
    );
  }
} 