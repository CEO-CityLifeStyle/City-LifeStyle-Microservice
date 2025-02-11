import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/place.dart';

class MapWidget extends StatefulWidget {
  final List<Place> places;
  final Function(Place)? onPlaceSelected;

  const MapWidget({
    Key? key,
    required this.places,
    this.onPlaceSelected,
  }) : super(key: key);

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  late GoogleMapController _controller;
  Map<MarkerId, Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _createMarkers();
  }

  void _createMarkers() {
    _markers = {};
    for (var place in widget.places) {
      final markerId = MarkerId(place.id);
      final marker = Marker(
        markerId: markerId,
        position: LatLng(place.latitude, place.longitude),
        infoWindow: InfoWindow(
          title: place.name,
          snippet: place.description,
          onTap: () {
            if (widget.onPlaceSelected != null) {
              widget.onPlaceSelected!(place);
            }
          },
        ),
      );
      _markers[markerId] = marker;
    }
  }

  @override
  void didUpdateWidget(MapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.places != widget.places) {
      _createMarkers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        _controller = controller;
        if (widget.places.isNotEmpty) {
          _fitBounds();
        }
      },
      initialCameraPosition: CameraPosition(
        target: widget.places.isNotEmpty
            ? LatLng(widget.places.first.latitude, widget.places.first.longitude)
            : const LatLng(0, 0),
        zoom: 12,
      ),
      markers: Set<Marker>.of(_markers.values),
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: true,
      mapToolbarEnabled: true,
    );
  }

  void _fitBounds() {
    if (widget.places.isEmpty) return;

    double minLat = widget.places.first.latitude;
    double maxLat = widget.places.first.latitude;
    double minLng = widget.places.first.longitude;
    double maxLng = widget.places.first.longitude;

    for (var place in widget.places) {
      if (place.latitude < minLat) minLat = place.latitude;
      if (place.latitude > maxLat) maxLat = place.latitude;
      if (place.longitude < minLng) minLng = place.longitude;
      if (place.longitude > maxLng) maxLng = place.longitude;
    }

    _controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50, // padding
      ),
    );
  }
}
