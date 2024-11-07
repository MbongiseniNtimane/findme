import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContactPage extends StatelessWidget {
  ContactPage({super.key});

  void _launchURL(String url) async {
    if (!await launch(url)) {
      throw 'Could not launch $url';
    }
  }

  void _launchPhone() async {
    const phoneUrl = 'tel:0783110232'; // Replace with your phone number
    _launchURL(phoneUrl);
  }

  void _launchEmail() async {
    const emailUrl = 'mailto:support@example.com'; // Replace with your email
    _launchURL(emailUrl);
  }

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController messageController = TextEditingController();

    return Scaffold(
      /* appBar: AppBar(
        title: const Text(
          'Contact Us',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20.0,
            fontFamily: 'sans-serif-light',
            color: Colors.black,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 145, 0),
      ),*/
      body: SingleChildScrollView(
        child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 255, 145, 0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.phone, size: 100, color: Color(0xFFBF360C)),
                const Text(
                  'Contact Us',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Form(
                  key: formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          border: const OutlineInputBorder(),
                          labelStyle: const TextStyle(fontSize: 16.0),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.grey.shade400, width: 2.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.grey.shade400, width: 2.0),
                          ),
                        ),
                        style: const TextStyle(color: Colors.black),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: const OutlineInputBorder(),
                          labelStyle: const TextStyle(fontSize: 16.0),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.grey.shade400, width: 2.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.grey.shade400, width: 2.0),
                          ),
                        ),
                        style: const TextStyle(color: Colors.black),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                              .hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: messageController,
                        decoration: InputDecoration(
                          labelText: 'Message',
                          border: const OutlineInputBorder(),
                          labelStyle: const TextStyle(fontSize: 16.0),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.grey.shade400, width: 2.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.grey.shade400, width: 2.0),
                          ),
                        ),
                        style: const TextStyle(color: Colors.black),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your message';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState?.validate() == true) {
                            final String name = nameController.text;
                            final String email = emailController.text;
                            final String messageText = messageController.text;
                            // final Timestamp timestamp = Timestamp.now();

                            // Create a Message object
                            final message = Message(
                              name: name,
                              email: email,
                              message: messageText,
                              // timestamp: timestamp,
                            );

                            // Save message to Firestore
                            saveMessageToFirestore(message);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ThankYouPage(title: ''),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[900], // Primary color
                          foregroundColor: Colors.white, // Text color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                        ),
                        child: const Text('Send'),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.facebook,
                                size: 50, color: Color(0xFF1877F2)),
                            onPressed: () =>
                                _launchURL('https://www.facebook.com/'),
                          ),
                          const SizedBox(width: 20),
                          IconButton(
                            icon: const Icon(Icons.phone,
                                size: 50,
                                color: Color.fromARGB(255, 82, 204, 12)),
                            onPressed: _launchPhone,
                          ),
                          const SizedBox(width: 20),
                          IconButton(
                            icon: const Icon(Icons.email,
                                size: 50, color: Colors.white),
                            onPressed: _launchEmail,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          const Text(
                            'Our Team',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SingleChildScrollView(
                            scrollDirection:
                                Axis.horizontal, // Enable horizontal scrolling
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment
                                  .center, // Center the row contents
                              children: List.generate(
                                teamMembers.length,
                                (index) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal:
                                          10.0), // Add space between cards
                                  child: _buildTeamCard(
                                    imagePath: teamMembers[index]['imagePath']!,
                                    name: teamMembers[index]['name']!,
                                    email: teamMembers[index]['email']!,
                                    location: teamMembers[index]['location']!,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            )),
      ),
    );
  }

  Widget _buildTeamCard({
    required String imagePath,
    required String name,
    required String email,
    required String location,
  }) {
    return Card(
      color: Colors.orange[900],
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage(imagePath),
              radius: 30,
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
                Text(email),
                Text(location),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Team members data
  final List<Map<String, String>> teamMembers = [
    
    {
      'imagePath': 'assets/images/team_member_1.jpg',
      'name': 'Mbongiseni Ntimane',
      'email': 'MNtimane@gmai.com',
      'location': 'Johannesburg',
    },
   
   
    // Add more members as needed
  ];
  // Function to save message to Firestore
  void saveMessageToFirestore(Message message) async {
    final CollectionReference messages =
        FirebaseFirestore.instance.collection('messages');
    await messages.add(message.toMap());
  }
}

// Message class for handling messages
class Message {
  final String name;
  final String email;
  final String message;
  //final Timestamp timestamp;

  Message({
    required this.name,
    required this.email,
    required this.message,
    //required this.timestamp,
  });

  // Convert Message object to a map for database storage or serialization
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'message': message,
      //'timestamp': timestamp,
    };
  }

  // Convert a map to a Message object for retrieval from storage
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      message: map['message'] ?? '',
      //timestamp: map['timestamp'] as Timestamp,
    );
  }
}

class ThankYouPage extends StatefulWidget {
  const ThankYouPage({super.key, required this.title});

  final String title;

  @override
  State<ThankYouPage> createState() => _ThankYouPageState();
}

Color themeColor = const Color.fromARGB(255, 0, 0, 0);

class _ThankYouPageState extends State<ThankYouPage> {
  double screenWidth = 600;
  double screenHeight = 400;
  Color textColor = const Color.fromARGB(255, 0, 0, 0);

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 145, 0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              height: 170,
              padding: const EdgeInsets.all(0),
              child: Image.asset(
                "assets/images/handshake.png",
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              "Thank you",
              style: TextStyle(
                color: themeColor,
                fontWeight: FontWeight.w600,
                fontSize: 36,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            const Text(
              "Message sent successfully",
              style: TextStyle(
                color: Color(0xff535353),
                fontWeight: FontWeight.w400,
                fontSize: 17,
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            const Text(
              "We will get back to you soon",
              style: TextStyle(
                color: Color(0xff535353),
                fontWeight: FontWeight.w400,
                fontSize: 17,
              ),
            ),
            SizedBox(height: screenHeight * 0.05),
            SizedBox(height: screenHeight * 0.06),
          ],
        ),
      ),
    );
  }
}
