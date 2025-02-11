import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/search_provider.dart';
import '../../models/place.dart';
import '../../utils/map_utils.dart';

class MapView extends StatefulWidget {
  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  GoogleMapController? _mapController;
  Map<MarkerId, Marker> _markers = {};
  bool _isLoading = false;
  BitmapDescriptor? _defaultMarker;
  BitmapDescriptor? _selectedMarker;

  @override
  void initState() {
    super.initState();
    _initializeMarkerIcons();
  }

  Future<void> _initializeMarkerIcons() async {
    _defaultMarker = await MapUtils.createCustomMarkerBitmap(
      'assets/icons/marker.png',
      size: 100,
    );
    _selectedMarker = await MapUtils.createCustomMarkerBitmap(
      'assets/icons/marker_selected.png',
      size: 120,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, searchProvider, child) {
        if (_isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: searchProvider.currentLocation ?? LatLng(0, 0),
                zoom: 13,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
                _updateMarkers(searchProvider.searchResults);
              },
              markers: Set<Marker>.of(_markers.values),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
              onCameraMove: (position) {
                // Update visible region
                if (_mapController != null) {
                  searchProvider.updateVisibleRegion(
                    _mapController!.getVisibleRegion(),
                  );
                }
              },
              onCameraIdle: () {
                // Fetch places for new region
                searchProvider.searchInVisibleRegion();
              },
            ),
            if (searchProvider.selectedPlace != null)
              _buildPlaceDetails(searchProvider.selectedPlace!),
          ],
        );
      },
    );
  }

  void _updateMarkers(List<Place> places) {
    setState(() {
      _markers.clear();
      for (var place in places) {
        final markerId = MarkerId(place.id);
        _markers[markerId] = Marker(
          markerId: markerId,
          position: LatLng(place.location.latitude, place.location.longitude),
          icon: _defaultMarker ?? BitmapDescriptor.defaultMarker,
          onTap: () {
            _onMarkerTapped(place);
          },
          infoWindow: InfoWindow(
            title: place.name,
            snippet: place.category,
          ),
        );
      }
    });
  }

  void _onMarkerTapped(Place place) {
    final searchProvider = Provider.of<SearchProvider>(context, listen: false);
    searchProvider.selectPlace(place);

    // Update marker appearance
    setState(() {
      final markerId = MarkerId(place.id);
      _markers[markerId] = _markers[markerId]!.copyWith(
        iconParam: _selectedMarker ?? BitmapDescriptor.defaultMarker,
      );
    });

    // Animate camera to selected place
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(place.location.latitude, place.location.longitude),
        15,
      ),
    );
  }

  Widget _buildPlaceDetails(Place place) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          place.category,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      Provider.of<SearchProvider>(context, listen: false)
                          .selectPlace(null);
                    },
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 20),
                  SizedBox(width: 4),
                  Text(
                    '${place.rating.toStringAsFixed(1)} (${place.reviewCount})',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.attach_money, color: Colors.green, size: 20),
                  SizedBox(width: 4),
                  Text(
                    place.priceLevel,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.directions),
                      label: Text('Directions'),
                      onPressed: () {
                        MapUtils.openDirections(
                          place.location.latitude,
                          place.location.longitude,
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.info_outline),
                      label: Text('Details'),
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/place-details',
                          arguments: place,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
