import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/place_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/place.dart';
import '../../widgets/map_widget.dart';
import '../../widgets/opening_hours_widget.dart';
import '../../services/upload_service.dart';

class AddEditPlaceScreen extends StatefulWidget {
  final Place? place;

  const AddEditPlaceScreen({super.key, this.place});

  @override
  State<AddEditPlaceScreen> createState() => _AddEditPlaceScreenState();
}

class _AddEditPlaceScreenState extends State<AddEditPlaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _uploadService = UploadService();
  String _selectedCategory = 'restaurant';
  LatLng? _selectedLocation;
  List<String> _images = [];
  final List<File> _newImages = [];
  bool _isLoading = false;
  Map<String, DayHours> _openingHours = {
    'monday': DayHours(isOpen: false),
    'tuesday': DayHours(isOpen: false),
    'wednesday': DayHours(isOpen: false),
    'thursday': DayHours(isOpen: false),
    'friday': DayHours(isOpen: false),
    'saturday': DayHours(isOpen: false),
    'sunday': DayHours(isOpen: false),
  };

  final List<String> _categories = [
    'restaurant',
    'cafe',
    'park',
    'museum',
    'shopping',
    'entertainment',
    'other'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.place != null) {
      _nameController.text = widget.place!.name;
      _descriptionController.text = widget.place!.description;
      _selectedCategory = widget.place!.category;
      _selectedLocation = LatLng(
        widget.place!.location.latitude,
        widget.place!.location.longitude,
      );
      _addressController.text = widget.place!.location.address;
      _phoneController.text = widget.place!.contact.phone ?? '';
      _emailController.text = widget.place!.contact.email ?? '';
      _websiteController.text = widget.place!.contact.website ?? '';
      _images = List.from(widget.place!.images);
      _openingHours = widget.place!.openingHours.hours;
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _newImages.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      _showErrorDialog('Failed to pick image. Please try again.');
    }
  }

  Future<void> _uploadImages(String token) async {
    if (_newImages.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final uploadedUrls = await _uploadService.uploadMultipleImages(_newImages, token);
      if (!mounted) return;
      
      setState(() {
        _images.addAll(uploadedUrls);
        _newImages.clear();
      });
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Failed to upload images. Please try again.');
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteImage(String imageUrl, String token) async {
    try {
      await _uploadService.deleteImage(imageUrl, token);
      if (!mounted) return;
      
      setState(() {
        _images.remove(imageUrl);
      });
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Failed to delete image. Please try again.');
    }
  }

  Future<void> _savePlace() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;
      if (token == null) {
        throw Exception('Authentication token not found');
      }
      
      // Upload new images first
      await _uploadImages(token);
      if (!mounted) return;

      final openingHours = OpeningHours(
        monday: _openingHours['monday'] ?? DayHours(isOpen: false),
        tuesday: _openingHours['tuesday'] ?? DayHours(isOpen: false),
        wednesday: _openingHours['wednesday'] ?? DayHours(isOpen: false),
        thursday: _openingHours['thursday'] ?? DayHours(isOpen: false),
        friday: _openingHours['friday'] ?? DayHours(isOpen: false),
        saturday: _openingHours['saturday'] ?? DayHours(isOpen: false),
        sunday: _openingHours['sunday'] ?? DayHours(isOpen: false),
      );

      final place = Place(
        id: widget.place?.id ?? '',
        name: _nameController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
        location: PlaceLocation(
          latitude: _selectedLocation!.latitude,
          longitude: _selectedLocation!.longitude,
          address: _addressController.text,
        ),
        images: _images,
        openingHours: openingHours,
        contact: Contact(
          phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
          email: _emailController.text.isNotEmpty ? _emailController.text : null,
          website: _websiteController.text.isNotEmpty ? _websiteController.text : null,
        ),
        rating: widget.place?.rating ?? 0.0,
        reviews: widget.place?.reviews ?? [],
        isFavorite: widget.place?.isFavorite ?? false,
        createdBy: widget.place?.createdBy ?? authProvider.currentUser?.id ?? 'unknown',
        createdAt: widget.place?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        categories: [_selectedCategory],
        priceRange: widget.place?.priceRange ?? 1,
        popularityScore: widget.place?.popularityScore ?? 0.0,
        lastUpdated: DateTime.now(),
      );

      final placeProvider = context.read<PlaceProvider>();
      if (widget.place != null) {
        await placeProvider.updatePlace(place);
      } else {
        await placeProvider.createPlace(place);
      }
      
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      _showErrorDialog('Failed to save place. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('Okay'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required void Function(String?)? onChanged,
    required String? initialValue,
    bool visible = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Visibility(
      visible: visible,
      child: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(labelText: label),
        keyboardType: keyboardType,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.place != null ? 'Edit Place' : 'Add Place'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePlace,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildFormField(
              label: 'Name *',
              onChanged: (value) => _nameController.text = value ?? '',
              initialValue: _nameController.text,
              visible: true,
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),
            _buildFormField(
              label: 'Description *',
              onChanged: (value) => _descriptionController.text = value ?? '',
              initialValue: _descriptionController.text,
              visible: true,
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category *',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: MapWidget(
                initialPosition: _selectedLocation,
                isSelecting: true,
                onLocationSelected: (location) {
                  setState(() {
                    _selectedLocation = location;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildFormField(
              label: 'Address *',
              onChanged: (value) => _addressController.text = value ?? '',
              initialValue: _addressController.text,
              visible: true,
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Images',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_photo_alternate),
                    onPressed: _pickImage,
                  ),
                ],
              ),
            if (_images.isNotEmpty || _newImages.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._images.map((imageUrl) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          Image.network(
                            imageUrl,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.white),
                              onPressed: () => _deleteImage(
                                imageUrl,
                                context.read<AuthProvider>().getToken() ?? '',
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                    ..._newImages.map((imageFile) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          Image.file(
                            imageFile,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.white),
                              onPressed: () {
                                setState(() {
                                  _newImages.remove(imageFile);
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            OpeningHoursWidget(
              openingHours: _openingHours,
              onChanged: (hours) {
                setState(() {
                  _openingHours = hours;
                });
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Contact Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildFormField(
              label: 'Phone',
              onChanged: (value) => _phoneController.text = value ?? '',
              initialValue: _phoneController.text,
              visible: true,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildFormField(
              label: 'Email',
              onChanged: (value) => _emailController.text = value ?? '',
              initialValue: _emailController.text,
              visible: true,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildFormField(
              label: 'Website',
              onChanged: (value) => _websiteController.text = value ?? '',
              initialValue: _websiteController.text,
              visible: true,
              keyboardType: TextInputType.url,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    super.dispose();
  }
}
