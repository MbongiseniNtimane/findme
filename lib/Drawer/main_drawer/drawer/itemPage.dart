import 'package:findme/Drawer/main_drawer/post_controller.dart/post_controller.dart';
import 'package:findme/screens/create_post.dart';
import 'package:findme/screens/post_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

class ItemPage extends StatefulWidget {
  const ItemPage({super.key});

  @override
  _ItemPageState createState() => _ItemPageState();
}

class _ItemPageState extends State<ItemPage> {
  final PostController postController = Get.find();
  String _selectedItemType = 'Lost';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await postController.fetchPosts(_selectedItemType);
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch posts');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 145, 0),
      /*: AppBar(
        title: const Text(
          'ITEMS',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20.0,
            fontFamily: 'sans-serif-light',
            color: Colors.black,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 145, 0),
      ),*/
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Explore Lost and Found Items Below',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          _buildItemTypeButtons(),
          const SizedBox(height: 20),
          //_buildStorySection(),
          const SizedBox(height: 20),
          Expanded(child: _buildPostsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreatePost,
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Colors.deepPurpleAccent),
      ),
    );
  }

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
        _fetchPosts();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _selectedItemType == type ? activeColor : Colors.grey,
      ),
      child: Text(type),
    );
  }

  /* Widget _buildStorySection() {
    return SizedBox(
      height: 120,
      child: Obx(() {
        final stories = postController.posts;
        return ListView(
          scrollDirection: Axis.horizontal,
          children: List.generate(stories.length, (index) {
            final post = stories[index];
            return _buildStoryCard(post);
          }),
        );
      }),
    );
  }

  Widget _buildStoryCard(PostItem post) {
    return GestureDetector(
      onTap: () {
        // Navigate to post item page with the selected post
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PostItemPage(post: post), // Assumes a PostItemPage exists
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey[300],
              ),
              child: _getStoryImage(post.imagePath),
            ),
            const SizedBox(height: 5),
            Text(
              post.itemName,
              style: const TextStyle(fontSize: 10),
            ), // Example text
          ],
        ),
      ),
    );
  }

  Widget _getStoryImage(dynamic imagePath) {
    if (imagePath == null || (imagePath is String && imagePath.isEmpty)) {
      return const Icon(Icons.add_a_photo, color: Colors.white);
    } else if (imagePath is Uint8List) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.broken_image, color: Colors.red);
          },
        ),
      );
    } else if (imagePath is String) {
      if (kIsWeb) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.broken_image, color: Colors.red);
            },
          ),
        );
      } else {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(imagePath),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.broken_image, color: Colors.red);
            },
          ),
        );
      }
    } else {
      return const Icon(Icons.error, color: Colors.red);
    }
  }*/

  Widget _buildPostsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Obx(() {
      final filteredPosts = postController.posts
          .where((post) => post.itemType == _selectedItemType)
          .toList();

      if (filteredPosts.isEmpty) {
        return const Center(
          child: Text(
            'No posts available',
            style: TextStyle(fontSize: 18, color: Colors.black),
          ),
        );
      }

      return ListView.builder(
        itemCount: filteredPosts.length,
        itemBuilder: (context, index) {
          final post = filteredPosts[index];
          return PostItemCard(
            itemName: post.itemName,
            description: post.description,
            //email: post.email,
            posterName: post.posterName,
            contactDetails: post.contactDetails,
            course: post.course,
            category: post.category,
            itemType: post.itemType,
            postedTime: post.postedTime, // Ensure this is the correct format
            imagePath: post.imagePath,
            onEdit: () => _navigateToEditPost(post),
            onDelete: () => _confirmDelete(context, post),
            onShare: () => _sharePost(post),
            latitude: post.latitude,
            longitude: post.longitude,
          );
        },
      );
    });
  }

  Future<void> _navigateToEditPost(PostItem post) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateLostItemPage(post: post),
      ),
    );
    if (result is PostItem) {
      await postController.updatePostInFirestore(result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post edited successfully!')),
      );
    }
  }

  void _confirmDelete(BuildContext context, PostItem post) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this post?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await postController.deletePost(post);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post deleted successfully!')),
                );
                Navigator.of(context).pop(); // Dismiss dialog
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToCreatePost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateLostItemPage(),
      ),
    );
    if (result is PostItem) {
      postController.addPost(result);
    }
  }

  void _sharePost(PostItem post) {
    final postDetails = '''
    Item Name: ${post.itemName}
    Description: ${post.description}
    Posted By: ${post.posterName}
    Contact: ${post.contactDetails}
    Course: ${post.course}
    Category: ${post.category}
    Item Type: ${post.itemType}
    Posted ${DateTime.now().difference(post.postedTime).inMinutes} minutes ago
    ''';
    Share.share(postDetails);
  }
}
