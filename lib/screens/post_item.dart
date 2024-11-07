import 'package:findme/screens/LocationPicker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart'; // for Image Picker
import 'dart:io'; // For File handling
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:geolocator/geolocator.dart'; // Import Geolocator

class PostItem {
  String id;
  String userID;
  String itemName;
  String description;
  //String email;
  String posterName;
  String contactDetails;
  String course;
  String category;
  String itemType;
  DateTime postedTime;
  String? imagePath;
  double? latitude;
  double? longitude;

  PostItem({
    this.id = '',
    required this.userID,
    required this.itemName,
    required this.description,
    //required this.email,
    required this.posterName,
    required this.contactDetails,
    required this.course,
    required this.category,
    required this.itemType,
    required this.postedTime,
    this.imagePath,
    this.latitude,
    this.longitude,
  });

  factory PostItem.fromFirestore(Map<String, dynamic> data, String id) {
    return PostItem(
      id: id,
      userID: data['UserID'] ?? '',
      itemName: data['ItemName'] ?? '',
      description: data['Description'] ?? '',
      //email: data['Email'] ?? '',
      posterName: data['PosterName'],
      contactDetails: data['ContactDetails'] ?? '',
      course: data['Course'] ?? '',
      category: data['Category'] ?? '',
      itemType: data['ItemType'] ?? '',
      postedTime: (data['PostedTime'] as Timestamp).toDate(),
      imagePath: data['ImagePath'],
      latitude: data['Latitude'],
      longitude: data['Longitude'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'UserID': userID,
      'ItemName': itemName,
      'Description': description,
      //'Email': email,
      'PosterName': posterName,
      'ContactDetails': contactDetails,
      'Course': course,
      'Category': category,
      'ItemType': itemType,
      'PostedTime': Timestamp.fromDate(postedTime),
      'ImagePath': imagePath,
      'Latitude': latitude,
      'Longitude': longitude,
    };
  }
}

class PostItemCard extends StatefulWidget {
  final String itemName;
  final String description;
  //final String email;
  final String posterName;
  final String contactDetails;
  final String course;
  final String category;
  final String itemType;
  final DateTime postedTime;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final String? imagePath;
  final double? latitude; // Nullable latitude
  final double? longitude; // Nullable longitude

  const PostItemCard({
    super.key,
    required this.itemName,
    required this.description,
    // required this.email,
    required this.posterName,
    required this.contactDetails,
    required this.course,
    required this.category,
    required this.itemType,
    required this.postedTime,
    required this.onEdit,
    required this.onDelete,
    required this.onShare,
    this.latitude,
    this.longitude,
    this.imagePath,
  });

  @override
  _PostItemCardState createState() => _PostItemCardState();
}

class _PostItemCardState extends State<PostItemCard> {
  String? _downloadURL;
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  double? _latitude;
  double? _longitude;

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      print('Error getting location: $e');
      Get.snackbar('Error', 'Could not get current location: ${e.toString()}',
          backgroundColor: Colors.red);
    }
  }

  void _sharePost() {
    final postDetails = '''
    Item Name: ${widget.itemName}
    Description: ${widget.description}
    Posted By : ${widget.posterName}
    Contact: ${widget.contactDetails}
    Course: ${widget.course}
    Category: ${widget.category}
    Item Type: ${widget.itemType}
    Posted ${DateTime.now().difference(widget.postedTime).inMinutes} minutes ago
    Location: $_latitude, $_longitude
    ''';
    Share.share(postDetails);
  }

  Widget _displayImage() {
    if (_downloadURL != null && _downloadURL!.isNotEmpty) {
      return Image.network(
        _downloadURL!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 200,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      (loadingProgress.expectedTotalBytes ?? 1)
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.error, size: 200);
        },
      );
    } else if (widget.imagePath != null) {
      return kIsWeb
          ? Image.network(
              widget.imagePath!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 200,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            (loadingProgress.expectedTotalBytes ?? 1)
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.error, size: 200);
              },
            )
          : Image.file(
              File(widget.imagePath!),
              fit: BoxFit.cover,
              width: double.infinity,
              height: 200,
            );
    } else {
      return const Icon(
        Icons.image,
        size: 200,
      );
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      try {
        if (kIsWeb) {
          final Uint8List imageBytes = await pickedFile.readAsBytes();
          String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
          final Reference storageRef =
              _storage.ref().child('post_images/$fileName');
          final UploadTask uploadTask = storageRef.putData(imageBytes);
          final TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
          final String downloadURL = await snapshot.ref.getDownloadURL();

          setState(() {
            _downloadURL = downloadURL;
          });

          await FirebaseFirestore.instance
              .collection('Posts')
              .doc(widget.itemName)
              .update({
            'imageURL': downloadURL,
          });
        } else {
          final File imageFile = File(pickedFile.path);
          String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
          final Reference storageRef =
              _storage.ref().child('post_images/$fileName');
          final UploadTask uploadTask = storageRef.putFile(imageFile);
          final TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
          final String downloadURL = await snapshot.ref.getDownloadURL();

          setState(() {
            _downloadURL = downloadURL;
          });

          await FirebaseFirestore.instance
              .collection('Posts')
              .doc(widget.itemName)
              .update({
            'imageURL': downloadURL,
          });
        }
      } catch (e) {
        print('Error uploading image: $e');
      }
    }
  }

  void _selectLocation() async {
    // Get the current location
    await _getCurrentLocation();

    // Proceed to the LocationPicker
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPicker(
          onLocationPicked: (latitude, longitude) async {
            setState(() {
              _latitude = latitude;
              _longitude = longitude;
            });

            await FirebaseFirestore.instance
                .collection('Posts')
                .doc(widget.itemName)
                .update({
              'Latitude': latitude,
              'Longitude': longitude,
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 450, // Match the specified width
      child: Card(
        color: Colors.orange.shade300,
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.itemName,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: widget.onEdit,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: widget.onDelete,
                      ),
                      IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: _sharePost,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(widget.description),
              const SizedBox(height: 8),
              if (widget.imagePath != null && widget.imagePath!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: kIsWeb
                      ? Image.network(
                          widget.imagePath!,
                          fit: BoxFit.cover,
                          width: 200,
                          height: 200,
                        )
                      : Image.file(
                          File(widget.imagePath!),
                          fit: BoxFit.cover,
                          width: 200,
                          height: 200,
                        ),
                ),
              const SizedBox(height: 8),
              Text(
                'Posted: ${widget.postedTime}',
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                'Contact: ${widget.contactDetails}',
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                'Course: ${widget.course}',
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                'Category: ${widget.category}',
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                'Type: ${widget.itemType}',
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                'Posted By: ${widget.posterName}',
                style: const TextStyle(fontSize: 12),
              ),
              if (widget.latitude != null && widget.longitude != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Location: Latitude ${widget.latitude}, Longitude ${widget.longitude}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
