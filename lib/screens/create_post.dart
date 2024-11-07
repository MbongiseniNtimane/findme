import 'dart:typed_data'; // For web, use Uint8List to store image bytes
import 'package:flutter/foundation.dart'; // To detect if running on web
import 'package:image_picker/image_picker.dart';
import 'package:findme/Drawer/main_drawer/post_controller.dart/post_controller.dart';
import 'package:findme/screens/post_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Import Firebase Storage
import 'package:geolocator/geolocator.dart'; // Import Geolocator

class CreateLostItemPage extends StatefulWidget {
  final PostItem? post;

  const CreateLostItemPage({super.key, this.post});

  @override
  _CreateLostItemPageState createState() => _CreateLostItemPageState();
}

class _CreateLostItemPageState extends State<CreateLostItemPage> {
  final PostController postController = Get.find();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contactDetailsController =
      TextEditingController();
  final TextEditingController _posterNameController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _latitudeController =
      TextEditingController(); // New
  final TextEditingController _longitudeController =
      TextEditingController(); // New

  String? _selectedCategory;
  bool _isLostItem = true;
  bool _isLoading = false;
  Uint8List? _selectedImageBytes; // Store image bytes for web
  String? _uploadedImageUrl; // Firebase Storage URL

  // List of categories
  final List<String> categories = [
    'General',
    'ID Card',
    'Backpack',
    'Phone',
    'Identity Card',
    'Books',
    'Keys',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.post != null) {
      _itemNameController.text = widget.post!.itemName;
      _descriptionController.text = widget.post!.description;
      _contactDetailsController.text = widget.post!.contactDetails;
      _posterNameController.text = widget.post!.posterName;

      _courseController.text = widget.post!.course;
      _selectedCategory = widget.post!.category ?? 'General';
      _isLostItem = widget.post!.itemType == 'Lost';
      if (widget.post!.imagePath != null) {
        _uploadedImageUrl =
            widget.post!.imagePath; // Load image URL from Firestore
      }
      // Set latitude and longitude if they exist in the post
      _latitudeController.text = widget.post?.latitude.toString() ?? '';
      _longitudeController.text = widget.post?.longitude.toString() ?? '';
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      // Read image bytes regardless of platform
      final imageBytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImageBytes = imageBytes; // Update image bytes state
      });
    }
  }

  Future<String?> _uploadImageToFirebase(Uint8List imageBytes) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference firebaseStorageRef = FirebaseStorage.instance
          .ref()
          .child('post_images/$fileName'); // Set path in Firebase Storage
      UploadTask uploadTask =
          firebaseStorageRef.putData(imageBytes); // Upload using bytes
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl =
          await taskSnapshot.ref.getDownloadURL(); // Get the image URL
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _latitudeController.text = position.latitude.toString();
        _longitudeController.text = position.longitude.toString();
      });
    } catch (e) {
      print('Error getting location: $e');
      Get.snackbar('Error', 'Could not get current location: ${e.toString()}',
          backgroundColor: Colors.red);
    }
  }

  void _savePost() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true; // Start loading
      });

      final User? currentUser = FirebaseAuth.instance.currentUser;
      final String userEmail = currentUser?.email ?? 'Unknown User';
      String? imageUrl;

      try {
        // Upload the image if a new one has been picked
        if (_selectedImageBytes != null && _selectedImageBytes!.isNotEmpty) {
          imageUrl = await _uploadImageToFirebase(_selectedImageBytes!);
        } else {
          imageUrl = widget.post?.imagePath; // Keep the existing image
        }

        // Parse latitude and longitude to double
        double? latitude = double.tryParse(_latitudeController.text);
        double? longitude = double.tryParse(_longitudeController.text);

        // Create a new post object
        final newPost = PostItem(
          id: widget.post?.id ??
              DateTime.now().millisecondsSinceEpoch.toString(), // Unique ID
          itemName: _itemNameController.text,
          description: _descriptionController.text,
          //email: userEmail,
          posterName: _posterNameController.text,
          contactDetails: _contactDetailsController.text,
          course: _courseController.text,
          latitude: latitude, // Assign parsed latitude
          longitude: longitude, // Assign parsed longitude
          category: _selectedCategory ?? 'General',
          itemType: _isLostItem ? 'Lost' : 'Found',
          postedTime: widget.post?.postedTime ?? DateTime.now(),
          userID: currentUser!.uid, // Ensure user is not null
          imagePath: imageUrl, // Store the URL in Firestore
        );

        // Add or update the post in Firestore
        if (widget.post != null) {
          await postController.updatePostInFirestore(newPost);
        } else {
          await postController.addPost(newPost);
        }

        Navigator.pop(
            context, newPost); // Go back to previous screen with the new post
      } catch (error) {
        // Use a more descriptive error message
        Get.snackbar('Error', 'Failed to save post: ${error.toString()}',
            backgroundColor: Colors.red);
      } finally {
        setState(() {
          _isLoading = false; // Stop loading
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color.fromARGB(255, 255, 145, 0), // Set background color
      appBar: AppBar(
        title: const Text(
          'Create Lost Item',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20.0,
            fontFamily: 'sans-serif-light',
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor:
            Colors.transparent, // Make the AppBar background transparent
        elevation: 0, // Remove the default elevation for a seamless look
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 255, 145, 0), // Start color
                Color.fromARGB(255, 255, 240, 219), // End color
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // Assign the form key
          child: ListView(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLostItem = true; // Set item type to Lost
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isLostItem ? Colors.red : Colors.grey,
                    ),
                    child: const Text('Lost'),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLostItem = false; // Set item type to Found
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          !_isLostItem ? Colors.green : Colors.grey,
                    ),
                    child: const Text('Found'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue; // Update selected category
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _itemNameController,
                decoration: const InputDecoration(labelText: 'Item Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter item name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _posterNameController,
                decoration: const InputDecoration(labelText: 'Posted By'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _contactDetailsController,
                decoration: const InputDecoration(labelText: 'Contact Details'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter contact details';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _courseController,
                decoration: const InputDecoration(labelText: 'Course'),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latitudeController,
                      decoration: const InputDecoration(labelText: 'Latitude'),
                      readOnly: true, // Prevent manual input
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.my_location),
                    onPressed: _getCurrentLocation, // Get current location
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _longitudeController,
                      decoration: const InputDecoration(labelText: 'Longitude'),
                      readOnly: true, // Prevent manual input
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  const SizedBox(height: 20),

                  // Display selected image at a fixed size if available, otherwise show nothing
                  _selectedImageBytes != null
                      ? SizedBox(
                          width: 100, // Set the desired width
                          height: 100, // Set the desired height
                          child: Image.memory(
                            _selectedImageBytes!,
                            fit: BoxFit
                                .cover, // Ensures the image fills the box without distortion
                          ),
                        )
                      : const SizedBox.shrink(),
                  const SizedBox(height: 20),

                  // Pick Image button with an icon
                  ElevatedButton.icon(
                    onPressed: _pickImage, // Pick an image from gallery
                    icon: const Icon(
                      Icons.image,
                      color: Colors.orange, // Use orange color for the icon
                    ),
                    label: const Text(
                      'Pick Image', // Button text
                      style: TextStyle(color: Colors.white), // Text color
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.orange[900], // Set the background color
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(50), // Rounded corners
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _savePost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[900], // Background color
                  foregroundColor: Colors.white, // Text color
                ),
                child: _isLoading
                    ? const CircularProgressIndicator() // Show loading indicator
                    : const Text('Save Post'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
