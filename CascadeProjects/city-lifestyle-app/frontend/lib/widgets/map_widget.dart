import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/place.dart';

class MapWidget extends StatefulWidget {
  final List<Place>? places;
  final Place? selectedPlace;
  final LatLng? initialPosition;
  final bool isSelecting;
  final Function(LatLng)? onLocationSelected;

  const MapWidget({
    super.key,
    this.places,
    this.selectedPlace,
    this.initialPosition,
    this.isSelecting = false,
    this.onLocationSelected,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  GoogleMapController? _controller;
  Map<MarkerId, Marker> _markers = {};
  LatLng? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _initializeMarkers();
  }

  @override
  void didUpdateWidget(MapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.places != oldWidget.places ||
        widget.selectedPlace != oldWidget.selectedPlace) {
      _initializeMarkers();
    }
  }

  void _initializeMarkers() {
    final markers = <MarkerId, Marker>{};

    if (widget.places != null) {
      for (final place in widget.places!) {
        final coordinates = place.location.coordinates;
        final latLng = LatLng(coordinates[1], coordinates[0]);
        final markerId = MarkerId(place.id);

        markers[markerId] = Marker(
          markerId: markerId,
          position: latLng,
          infoWindow: InfoWindow(
            title: place.name,
            snippet: place.location.address,
          ),
        );
      }
    }

    if (widget.selectedPlace != null) {
      final coordinates = widget.selectedPlace!.location.coordinates;
      final latLng = LatLng(coordinates[1], coordinates[0]);
      final markerId = MarkerId(widget.selectedPlace!.id);

      markers[markerId] = Marker(
        markerId: markerId,
        position: latLng,
        infoWindow: InfoWindow(
          title: widget.selectedPlace!.name,
          snippet: widget.selectedPlace!.location.address,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );

      _controller?.animateCamera(
        CameraUpdate.newLatLngZoom(latLng, 15),
      );
    }

    if (_selectedLocation != null) {
      markers[const MarkerId('selected')] = Marker(
        markerId: const MarkerId('selected'),
        position: _selectedLocation!,
        draggable: widget.isSelecting,
        onDragEnd: widget.isSelecting ? _onMarkerDragEnd : null,
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  void _onMapTapped(LatLng position) {
    if (!widget.isSelecting) return;

    setState(() {
      _selectedLocation = position;
      _markers = {
        const MarkerId('selected'): Marker(
          markerId: const MarkerId('selected'),
          position: position,
          draggable: true,
          onDragEnd: _onMarkerDragEnd,
        ),
      };
    });

    widget.onLocationSelected?.call(position);
  }

  void _onMarkerDragEnd(LatLng position) {
    setState(() {
      _selectedLocation = position;
    });
    widget.onLocationSelected?.call(position);
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: widget.initialPosition ??
            widget.selectedPlace != null
                ? LatLng(
                    widget.selectedPlace!.location.coordinates[1],
                    widget.selectedPlace!.location.coordinates[0],
                  )
                : const LatLng(24.7136, 46.6753), // Default to Riyadh
        zoom: widget.selectedPlace != null ? 15 : 10,
      ),
      markers: Set<Marker>.of(_markers.values),
      onMapCreated: (controller) {
        _controller = controller;
      },
      onTap: _onMapTapped,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      mapToolbarEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: true,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
