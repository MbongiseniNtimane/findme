import 'dart:io';
import 'dart:math'; // For demo data generation
import 'package:findme/Drawer/main_drawer/post_controller.dart/post_controller.dart';
import 'package:findme/screens/post_item.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fl_chart/fl_chart.dart'; // Import for chart

class Posts extends StatefulWidget {
  const Posts({super.key});

  @override
  _PostsState createState() => _PostsState();
}

class _PostsState extends State<Posts> {
  final PostController postController =
      Get.put(PostController()); // Registering here
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 145, 0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20), // Adds some space at the top
            const Text(
              'Chart of Lost and Found Items', // Title text
              style: TextStyle(
                fontSize: 24,
                color: Colors.black, // Title color set to black
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(
                height: 20), // Adds space between title and chart row
            Row(
              children: [
                Expanded(flex: 2, child: _buildChart()), // Chart on the left
                Expanded(
                    flex: 1, child: _buildCounter()), // Counter on the right
              ],
            ),
            _buildItemTypeButtons(),
            const SizedBox(height: 20),
            SizedBox(
              height: MediaQuery.of(context).size.height *
                  0.5, // Adjusts for available height
              child: _buildPostsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounter() {
    int lostCount =
        postController.posts.where((post) => post.itemType == 'Lost').length;
    int foundCount =
        postController.posts.where((post) => post.itemType == 'Found').length;

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildCounterText('Lost', lostCount, Colors.red),
          const SizedBox(height: 20),
          _buildCounterText('Found', foundCount, Colors.green),
        ],
      ),
    );
  }

  Widget _buildCounterText(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildChart() {
    // Initialize counters for lost and found items
    List<FlSpot> lostData = [];
    List<FlSpot> foundData = [];

    // Get the current date
    DateTime now = DateTime.now();

    // Loop through the last 7 days to collect data
    for (int i = 0; i < 7; i++) {
      DateTime date = now.subtract(Duration(days: i));

      // Count posts for 'Lost'
      int lostCount = postController.posts
          .where((post) =>
              post.itemType == 'Lost' &&
              post.postedTime.isAfter(date.subtract(const Duration(days: 1))) &&
              post.postedTime.isBefore(date))
          .length;

      // Count posts for 'Found'
      int foundCount = postController.posts
          .where((post) =>
              post.itemType == 'Found' &&
              post.postedTime.isAfter(date.subtract(const Duration(days: 1))) &&
              post.postedTime.isBefore(date))
          .length;

      lostData.add(FlSpot(i.toDouble(), lostCount.toDouble()));
      foundData.add(FlSpot(i.toDouble(), foundCount.toDouble()));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: true),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    return Text(value.toInt().toString());
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      'Day ${value.toInt() + 1}',
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: lostData,
                isCurved: true,
                color: Colors.red,
                barWidth: 3,
                belowBarData:
                    BarAreaData(show: true, color: Colors.red.withOpacity(0.3)),
                dotData: const FlDotData(show: false),
              ),
              LineChartBarData(
                spots: foundData,
                isCurved: true,
                color: Colors.green,
                barWidth: 3,
                belowBarData: BarAreaData(
                    show: true, color: Colors.green.withOpacity(0.3)),
                dotData: const FlDotData(show: false),
              ),
            ],
            borderData: FlBorderData(
              show: true,
              border: const Border(
                left: BorderSide(color: Colors.black, width: 1),
                bottom: BorderSide(color: Colors.black, width: 1),
              ),
            ),
            minX: 0,
            maxX: 6,
            minY: 0,
            maxY: max(lostData.map((e) => e.y).reduce(max),
                    foundData.map((e) => e.y).reduce(max)) +
                1,
          ),
        ),
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
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: filteredPosts.length,
        itemBuilder: (context, index) {
          final post = filteredPosts[index];
          return Column(
            children: [
              PostItemCard(
                itemName: post.itemName,
                description: post.description,
                //email: post.email,
                posterName: post.posterName,
                contactDetails: post.contactDetails,
                course: post.course,
                category: post.category,
                itemType: post.itemType,
                postedTime:
                    DateFormat('yyyy-MM-dd – kk:mm').format(post.postedTime),
                imagePath: post.imagePath,
                onDelete: () => _confirmDelete(context, post),
                onShare: () => _sharePost(post),
                latitude: post.latitude,
                longitude: post.longitude,
              ),
              const SizedBox(height: 10),
            ],
          );
        },
      );
    });
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
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await postController.deletePost(post);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post deleted successfully!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to delete post.')),
                  );
                } finally {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
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
    Posted ${_getTimeDifference(post.postedTime)}
  ''';

    Share.share(postDetails);
  }

  String _getTimeDifference(DateTime postedTime) {
    final difference = DateTime.now().difference(postedTime);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}

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
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final double? latitude;
  final double? longitude;

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
