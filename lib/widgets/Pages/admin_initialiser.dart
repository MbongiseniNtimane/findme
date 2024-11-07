import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminInitializer {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initializeAdminUser() async {
    try {
      // Check if admin user already exists in Firestore
      DocumentSnapshot adminSnapshot =
          await _firestore.collection('users').doc('admin@gmail.com').get();

      if (!adminSnapshot.exists) {
        // Create the admin user in Firebase Auth if it doesn't exist
        UserCredential userCredential;
        try {
          userCredential = await _auth.createUserWithEmailAndPassword(
            email: 'admin@gmail.com',
            password: 'Test!123',
          );
        } catch (e) {
          // If admin creation failed due to existing account, log in instead
          userCredential = await _auth.signInWithEmailAndPassword(
            email: 'admin@gmail.com',
            password: 'Test!123',
          );
        }

        // Ensure role is set as Admin in Firestore
        await _firestore
            .collection('users')
            .doc(userCredential.user!.email)
            .set({
          'email': userCredential.user!.email,
          'role': 'Admin',
        });

        print('Admin user created or confirmed successfully');
      } else {
        print('Admin user already exists');
      }
    } on FirebaseAuthException catch (e) {
      print("Admin creation error: $e");
    }
  }
}
