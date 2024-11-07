import 'dart:io';
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:findme/Drawer/main_drawer/post_controller.dart/post_controller.dart';
import 'package:findme/screens/create_post.dart';
import 'package:findme/screens/post_item.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
//import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PostController postController = Get.put(PostController());

  //final ImagePicker _picker = ImagePicker();
  Uint8List? selectedImageBytes;
  String _selectedItemType = 'Lost';

  final List<String> _imagePaths = [
    'assets/images/pic1.jpg',
    'assets/images/pic2.jpg',
    'assets/images/pic3.jpg',
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 145, 0),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: const AnimatedOpacity(
                duration: Duration(milliseconds: 300),
                opacity: 1.0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Lost Something? Find It Here.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Submit a lost or found item easily and help others.',
                      style: TextStyle(
                        fontSize: 12.0,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color.fromARGB(255, 255, 145, 0),
                      Colors.orange.shade300,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.search,
                        size: 50,
                        color: Colors.black54,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Helping you reconnect with your lost items.',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            backgroundColor: const Color.fromARGB(255, 255, 145, 0),
          ),
          SliverToBoxAdapter(
            child: _buildHomePage(context), // No need for SliverFillRemaining
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final PostItem? newPost = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateLostItemPage(),
            ),
          );
          // if (newPost != null) {
          //   postController.addPost(newPost);
          // }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHomePage(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        color: const Color.fromARGB(255, 255, 145, 0),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildCarouselSlider(),
            const SizedBox(height: 20),
            _buildItemTypeButtons(),
            const SizedBox(height: 20),
            _buildPostsList(),
          ],
        ),
      ),
    );
  }

  // Carousel for Featured Images
  Widget _buildCarouselSlider() {
    return CarouselSlider(
      options: CarouselOptions(
        height: 200.0,
        autoPlay: true,
        enlargeCenterPage: true,
        aspectRatio: 16 / 9,
        autoPlayCurve: Curves.fastOutSlowIn,
        enableInfiniteScroll: true,
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        viewportFraction: 0.8,
      ),
      items: _imagePaths.map((imagePath) {
        return Container(
          width: MediaQuery.of(context).size.width,
          margin: const EdgeInsets.symmetric(horizontal: 5.0),
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.circular(10.0),
          ),
        );
      }).toList(),
    );
  }

  // Buttons for Lost/Found Filters
  Widget _buildItemTypeButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _itemTypeButton('Lost', Colors.red),
        const SizedBox(width: 20),
        _itemTypeButton('Found', Colors.green),
      ],
    );
  }

  ElevatedButton _itemTypeButton(String type, Color activeColor) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedItemType = type;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _selectedItemType == type ? activeColor : Colors.grey,
      ),
      child: Text(type),
    );
  }

  // List of Posts
  Widget _buildPostsList() {
    return Obx(() {
      final filteredPosts = postController.posts
          .where((post) => post.itemType == _selectedItemType)
          .toList();

      if (filteredPosts.isEmpty) {
        return const Center(
          child: Text(
            'No post yet',
            style: TextStyle(fontSize: 18, color: Colors.black),
          ),
        );
      }

      return ListView.builder(
        shrinkWrap: true, // Use shrinkWrap to avoid infinite height
        physics:
            const NeverScrollableScrollPhysics(), // Disable outer scrolling
        itemCount: filteredPosts.length,
        itemBuilder: (context, index) {
          final post = filteredPosts[index];
          return Column(
            children: [
              PostItemCard(
                itemName: post.itemName,
                description: post.description,
                // email: post.email,
                posterName: post.posterName,
                contactDetails: post.contactDetails,
                course: post.course,
                category: post.category,
                itemType: post.itemType,
                postedTime: DateFormat('yyyy-MM-dd – kk:mm')
                    .format(post.postedTime), // Convert to String
                imagePath: post.imagePath,
                onEdit: () => _editPost(context, post),
                onDelete: () => _confirmDelete(context, post),
                onShare: () => _sharePost(post),
                latitude: post.latitude, // Pass latitude if available
                longitude: post.longitude,
              ),
              const SizedBox(height: 10),
            ],
          );
        },
      );
    });
  }

  void _editPost(BuildContext context, PostItem post) async {
    // Show a loading indicator while navigating
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Navigate to the edit page and await the result (edited post)
    final PostItem? editedPost = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateLostItemPage(post: post),
      ),
    );

    // Dismiss the loading indicator
    Navigator.of(context).pop();

    if (editedPost != null) {
      await postController.updatePostInFirestore(editedPost);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post edited successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Post not edited.')),
      );
    }
  }

  void _confirmDelete(BuildContext context, PostItem post) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Post'),
          content: const Text('Are you sure you want to delete this post?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                postController.deletePost(post);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post deleted successfully!')),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _sharePost(PostItem post) {
    final String shareContent =
        'Check out this ${post.itemType} item:\n\n${post.itemName}\n${post.description}\nContact: ${post.contactDetails}\nCourse: ${post.course}\nCategory: ${post.category}\n';
    Share.share(shareContent);
  }
}

// Define your PostItem and PostItemCard widgets as needed

class PostItemCard extends StatelessWidget {
  final String itemName;
  final String description;
  //final String email;
  final String posterName;
  final String contactDetails;
  final String course;
  final String category;
  final String itemType;
  final String postedTime;
  final dynamic imagePath;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final double? latitude; // Nullable latitude
  final double? longitude; // Nullable longitude

  const PostItemCard({
    super.key,
    required this.itemName,
    required this.description,
    //required this.email,
    required this.posterName,
    required this.contactDetails,
    required this.course,
    required this.category,
    required this.itemType,
    required this.postedTime,
    required this.imagePath,
    required this.onEdit,
    required this.onDelete,
    required this.onShare,
    this.latitude,
    this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 450,
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
                    itemName,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: onEdit,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: onDelete,
                      ),
                      IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: onShare,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(description),
              const SizedBox(height: 8),
              if (imagePath != null && imagePath.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: kIsWeb
                      ? Image.network(
                          imagePath,
                          fit: BoxFit.cover,
                          width: 200,
                          height: 200,
                        )
                      : Image.file(
                          File(imagePath),
                          fit: BoxFit.cover,
                          width: 200,
                          height: 200,
                        ),
                ),
              const SizedBox(height: 8),
              Text('Posted: $postedTime', style: const TextStyle(fontSize: 12)),
              Text('Contact: $contactDetails',
                  style: const TextStyle(fontSize: 12)),
              Text('Course: $course', style: const TextStyle(fontSize: 12)),
              Text('Category: $category', style: const TextStyle(fontSize: 12)),
              Text('Type: $itemType', style: const TextStyle(fontSize: 12)),
              Text('Posted By: $posterName',
                  style: const TextStyle(fontSize: 12)),

              // Display Latitude and Longitude if available
              if (latitude != null && longitude != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Location: Latitude $latitude, Longitude $longitude',
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
