import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findme/screens/post_item.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

class PostController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  var posts = <PostItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchPosts(); // Fetch posts on initialization
  }

  // Fetch posts from Firestore
  Future<void> fetchPosts([String itemType = 'Lost']) async {
    QuerySnapshot snapshot = await _firestore
        .collection('Posts')
        .where('ItemType', isEqualTo: itemType)
        .get();

    posts.value = snapshot.docs
        .map((doc) =>
            PostItem.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<void> addPost(PostItem post, {Uint8List? selectedImageBytes}) async {
    post.userID =
        FirebaseAuth.instance.currentUser!.uid; // Get the current user's ID

    // If imagePath is provided, upload the image and get the URL
    if (selectedImageBytes != null) {
      post.imagePath = await uploadImageToFirebase(selectedImageBytes);
    }

    // Add the post to Firestore
    DocumentReference docRef =
        await _firestore.collection('Posts').add(post.toFirestore());

    // Set the id of the post after it has been added to Firestore
    post.id = docRef.id;

    // Optionally add the post to a local list if needed
    posts.add(post);
  }

  Future<String> uploadImageToFirebase(Uint8List imageBytes) async {
    String fileName = DateTime.now()
        .millisecondsSinceEpoch
        .toString(); // Use a unique filename
    Reference storageRef =
        FirebaseStorage.instance.ref().child('post_images/$fileName');

    try {
      // Upload the image bytes to Firebase Storage
      UploadTask uploadTask = storageRef.putData(imageBytes);

      // Optionally listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot taskSnapshot) {
        print(
            'Upload is ${taskSnapshot.bytesTransferred} out of ${taskSnapshot.totalBytes} bytes');
      });

      // Await the upload task to complete and retrieve the download URL
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadURL = await taskSnapshot.ref.getDownloadURL();

      return downloadURL; // Return the image's download URL
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Image upload failed');
    }
  }

  // Update a post in Firestore and local state
  Future<void> updatePostInFirestore(PostItem updatedPost) async {
    await _firestore
        .collection('Posts')
        .doc(updatedPost.id)
        .set(updatedPost.toFirestore());
    int index = posts.indexWhere((post) => post.id == updatedPost.id);
    if (index != -1) {
      posts[index] = updatedPost;
    } else {
      print('Post not found for updating');
    }
  }

  // Delete a post from Firestore and local state
  Future<void> deletePost(PostItem post) async {
    try {
      await _firestore.collection('Posts').doc(post.id).delete();
      posts.remove(post);
      print('Post deleted: ${post.itemName}');
    } catch (e) {
      print('Error deleting post: $e');
      throw Exception('Failed to delete post');
    }
  }

  // Share post using the share_plus package
  void sharePost(PostItem post) {
    final postDetails = '''
      Item Name: ${post.itemName}
      Description: ${post.description}
      Posted By: ${post.posterName}
      Contact: ${post.contactDetails}
      Course: ${post.course}
      Category: ${post.category}
      Item Type: ${post.itemType}
      Posted ${DateTime.now().difference(post.postedTime).inMinutes} minutes ago
      Image: ${post.imagePath ?? 'No image available'}
    ''';

    Share.share(postDetails);
  }
}
