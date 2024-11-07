import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditing = false;
  String _selectedGender = 'Male';
  DateTime? _selectedDate;
  String? profilePictureUrl;
  File? _imageFile;
  Uint8List? _imageBytes;

  String? name;
  String? email;
  String? mobile;

  double _profileCompletion = 0.0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController dobController = TextEditingController();

  final ProfileController _profileController = Get.put(ProfileController());

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    User? user = _auth.currentUser;
    if (user?.email == null) return;

    try {
      var userProfile =
          await _firestore.collection('profile').doc(user!.email).get();
      if (userProfile.exists) {
        var data = userProfile.data();
        setState(() {
          name = data?['name'];
          email = data?['email'];
          mobile = data?['mobile'];
          _selectedGender = data?['gender'];
          _selectedDate = (data?['dob'] as Timestamp?)?.toDate();
          profilePictureUrl = data?['profilePicture'];

          nameController.text = name ?? '';
          emailController.text = email ?? '';
          mobileController.text = mobile ?? '';
        });
        _calculateProfileCompletion();
      }
    } catch (e) {
      print("Error fetching profile data: $e");
    }
  }

  void _calculateProfileCompletion() {
    int completedFields = 0;
    int totalFields = 6;

    if (name != null && name!.isNotEmpty) completedFields++;
    if (email != null && email!.isNotEmpty) completedFields++;
    if (mobile != null && mobile!.isNotEmpty) completedFields++;
    if (_selectedDate != null) completedFields++;
    if (_selectedGender.isNotEmpty) completedFields++;
    if (profilePictureUrl != null && profilePictureUrl!.isNotEmpty) {
      completedFields++;
    }

    setState(() {
      _profileCompletion = completedFields / totalFields;
    });
  }

  Future<void> _saveProfileData() async {
    User? user = _auth.currentUser;

    if (user != null && user.email != null) {
      try {
        DocumentReference userDoc =
            _firestore.collection('profile').doc(user.email);
        await userDoc.set({
          'name': nameController.text,
          'email': emailController.text,
          'mobile': mobileController.text,
          'gender': _selectedGender,
          'dob':
              _selectedDate != null ? Timestamp.fromDate(_selectedDate!) : null,
          'profilePicture': profilePictureUrl,
        }, SetOptions(merge: true));

        setState(() {
          _isEditing = false;
          name = nameController.text;
          email = emailController.text;
          mobile = mobileController.text;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      } catch (e) {
        print("Error saving profile data: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile.')),
        );
      }
    } else {
      print("User or user.email is null. Cannot save profile data.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to update profile. User not signed in.')),
      );
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    if (kIsWeb) {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final imageBytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = imageBytes;
        });

        try {
          profilePictureUrl =
              await _profileController.uploadProfilePictureWeb(_imageBytes!);
          if (profilePictureUrl != null) {
            setState(() {});
            await _saveProfileData();
          }
        } catch (e) {
          print('Error uploading image: $e');
        }
      }
    } else {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });

        try {
          profilePictureUrl =
              await _profileController.uploadProfilePicture(_imageFile!);
          if (profilePictureUrl != null) {
            setState(() {});
            await _saveProfileData();
          }
        } catch (e) {
          print('Error uploading image: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 145, 0),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 145, 0),
        title: const Text(''),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveProfileData,
            ),
        ],
      ),
      // backgroundColor: const Color.fromARGB(255, 255, 145, 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: profilePictureUrl != null
                        ? NetworkImage(profilePictureUrl!)
                        : _imageFile != null
                            ? FileImage(_imageFile!)
                            : _imageBytes != null
                                ? MemoryImage(_imageBytes!)
                                : const AssetImage(
                                        'assets/images/default_avatar.png')
                                    as ImageProvider,
                  ),
                  TextButton(
                    onPressed: _pickImage,
                    child: const Text(
                      'Change Profile Picture',
                      style: TextStyle(
                        color: Colors.black, // Set text color to black
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              enabled: _isEditing,
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              enabled: _isEditing,
            ),
            TextField(
              controller: mobileController,
              decoration: const InputDecoration(labelText: 'Mobile'),
              enabled: _isEditing,
            ),

            if (_isEditing)
              // Display Radio buttons for selecting gender when editing is enabled
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Male'),
                      leading: Radio<String>(
                        value: 'Male',
                        groupValue: _selectedGender,
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value!;
                          });
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('Female'),
                      leading: Radio<String>(
                        value: 'Female',
                        groupValue: _selectedGender,
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value!;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              )
            else
              // Display selected gender as plain text when editing is disabled, in a TextField style
              TextField(
                controller: TextEditingController(
                    text: _selectedGender), // Shows selected gender
                decoration: const InputDecoration(labelText: 'Gender'),
                readOnly: true, // Makes the field non-editable
                enabled: false, // Keeps the style consistent with other fields
              ),

// Date of Birth TextField with date picker
            TextField(
              controller:
                  dobController, // Define a TextEditingController for date of birth
              decoration: const InputDecoration(labelText: 'Date of Birth'),
              readOnly: true, // Makes the field non-editable
              onTap: _isEditing
                  ? () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null && pickedDate != _selectedDate) {
                        setState(() {
                          _selectedDate = pickedDate;
                          dobController.text =
                              '${pickedDate.day}/${pickedDate.month}/${pickedDate.year}';
                        });
                      }
                    }
                  : null,
              enabled: _isEditing,
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: _profileCompletion,
              backgroundColor: Colors.grey[300],
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFE65100)),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                'Profile Completion: ${(_profileCompletion * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileController extends GetxController {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Uploads profile picture for mobile (using File)
  Future<String?> uploadProfilePicture(File imageFile) async {
    try {
      // Generate a unique file name based on current time
      String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Reference to Firebase Storage
      Reference storageRef = _storage.ref().child('profile_pictures/$fileName');

      // Upload file to Firebase Storage
      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;

      // Retrieve and return the download URL
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading profile picture: $e");
      return null; // Return null if upload fails
    }
  }

  // Uploads profile picture for web (using Uint8List)
  Future<String?> uploadProfilePictureWeb(Uint8List imageBytes) async {
    try {
      // Generate a unique file name based on current time
      String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Reference to Firebase Storage
      Reference storageRef = _storage.ref().child('profile_pictures/$fileName');

      // Upload data (bytes) to Firebase Storage
      UploadTask uploadTask = storageRef.putData(imageBytes);
      TaskSnapshot taskSnapshot = await uploadTask;

      // Retrieve and return the download URL
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading profile picture on web: $e");
      return null; // Return null if upload fails
    }
  }
}
