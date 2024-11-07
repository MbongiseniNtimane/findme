import 'package:curved_drawer_fork/curved_drawer_fork.dart';
import 'package:findme/Drawer/main_drawer/drawer/contactPage.dart';
import 'package:findme/Drawer/main_drawer/drawer/homePage.dart';
import 'package:findme/Drawer/main_drawer/drawer/itemPage.dart';
import 'package:findme/Drawer/main_drawer/drawer/profilePage.dart';
import 'package:findme/widgets/Pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core for initialization

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
      // No 'home: DrawerPage' here as per your request
    );
  }
}

class DrawerPage extends StatefulWidget {
  //final String userID;
  //final String email;

  const DrawerPage({
    super.key,
    /*required this.userID*/ /*required this.email*/
  });
  @override
  _DrawerPageState createState() => _DrawerPageState();
}

class _DrawerPageState extends State<DrawerPage> {
  final _pageController = PageController();
  int _selectedPageIndex = 0; // Track the selected page index
  final FirebaseAuth _auth = FirebaseAuth.instance; // Initialize FirebaseAuth

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: Container(
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
          child: AppBar(
            centerTitle: true,
            title: const Text(
              'FindMe App',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20.0,
                fontFamily: 'sans-serif-light',
                color: Colors.black,
              ),
            ),
            backgroundColor:
                Colors.transparent, // Make the AppBar background transparent
            elevation: 0, // Remove the default elevation for a seamless look
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.search,
                  color:
                      Colors.black54, // Change icon color for better visibility
                ),
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: CustomSearchDelegate(_pageController),
                  );
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.notifications,
                  color:
                      Colors.black54, // Change icon color for better visibility
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsPage(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.logout,
                  color:
                      Colors.black54, // Change icon color for better visibility
                ),
                onPressed: () => _logout(
                    context), // Pass the context to the _logout function
              ),
            ],
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedPageIndex =
                index; // Update the index when the page changes
          });
        },
        children: <Widget>[
          const HomePage(),
          const ItemPage(),
          const ProfilePage(/*email: widget.email*/),
          ContactPage(),
        ],
      ),
      drawer: CurvedDrawer(
        color: const Color.fromARGB(255, 255, 145, 0),
        buttonBackgroundColor: Colors.lightGreenAccent,
        labelColor: Colors.red,
        backgroundColor: Colors.transparent,
        width: 75.0,
        items: const <DrawerItem>[
          DrawerItem(icon: Icon(Icons.home), label: "Home"),
          DrawerItem(icon: Icon(Icons.camera), label: "Items"),
          DrawerItem(icon: Icon(Icons.person), label: "Profile"),
          DrawerItem(icon: Icon(Icons.phone), label: "Contact"),
        ],
        index: _selectedPageIndex, // Highlight the selected item
        onTap: (index) {
          setState(() {
            _selectedPageIndex = index; // Update the selected page index
          });
          _pageController.animateToPage(index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut);
        },
      ),
    );
  }

  void _logout(BuildContext context) async {
    await _auth.signOut(); // Log out the user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged out successfully.')),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) =>
              const LoginScreen()), // Use your existing login page
    );
  }
}

class CustomSearchDelegate extends SearchDelegate {
  final PageController pageController;

  CustomSearchDelegate(this.pageController);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.toLowerCase().contains('home')) {
      pageController.jumpToPage(0);
    } else if (query.toLowerCase().contains('item')) {
      pageController.jumpToPage(1);
    } else if (query.toLowerCase().contains('profile')) {
      pageController.jumpToPage(2);
    } else if (query.toLowerCase().contains('contact')) {
      pageController.jumpToPage(3);
    } else {
      return Center(
        child: Text('No results found for "$query"'),
      );
    }

    close(context, null);
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: const Center(
        child: Text(
          'No new notifications',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
