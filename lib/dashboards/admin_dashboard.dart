import 'package:curved_drawer_fork/curved_drawer_fork.dart';
import 'package:findme/dashboards/ManageUsersPage.dart';
import 'package:findme/dashboards/messages.dart';
import 'package:findme/dashboards/posts.dart';
import 'package:findme/widgets/Pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
    );
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _pageController = PageController();
  int _selectedPageIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20.0,
            color: Colors.black,
          ),
        ),
        backgroundColor:
            Colors.transparent, // Make the AppBar background transparent
        elevation: 0, // Remove default elevation for a seamless look
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
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Colors
                  .white, // Change icon color to white for better visibility
            ),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedPageIndex = index;
          });
        },
        children: const <Widget>[
          Posts(),
          ManageUsersPage(),
          AdminMessagesPage(),
        ],
      ),
      drawer: CurvedDrawer(
        color: const Color.fromARGB(255, 255, 145, 0),
        buttonBackgroundColor: Colors.lightGreenAccent,
        labelColor: Colors.red,
        backgroundColor: Colors.transparent,
        width: 75.0,
        items: const <DrawerItem>[
          DrawerItem(icon: Icon(Icons.post_add), label: "View Posts"),
          DrawerItem(icon: Icon(Icons.person), label: "Manage Users"),
          DrawerItem(icon: Icon(Icons.message), label: "Messages"),
        ],
        index: _selectedPageIndex,
        onTap: (index) {
          setState(() {
            _selectedPageIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        },
      ),
    );
  }

  void _logout(BuildContext context) async {
    await _auth.signOut();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged out successfully.')),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }
}
