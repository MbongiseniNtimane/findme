import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminMessagesPage extends StatelessWidget {
  const AdminMessagesPage({super.key});

  // Method to delete a message from Firestore
  Future<void> _deleteMessage(String messageId) async {
    await FirebaseFirestore.instance
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  // Method to launch email client with a reply
  Future<void> _replyToMessage(String email, BuildContext context) async {
    TextEditingController replyController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reply to Message'),
          content: TextField(
            controller: replyController,
            maxLines: 3,
            decoration:
                const InputDecoration(hintText: 'Enter your reply here'),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final replyText = replyController.text;
                final Uri emailUri = Uri(
                  scheme: 'mailto',
                  path: email,
                  query: 'subject=Reply from Admin&body=$replyText',
                );

                if (await canLaunchUrl(emailUri)) {
                  await launchUrl(emailUri);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Could not open email client.')),
                  );
                }

                Navigator.of(context).pop();
              },
              child: const Text('Send'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 145, 0),
      /*appBar: AppBar(
        title: const Text('Admin Messages'),
        backgroundColor: const Color.fromARGB(255, 255, 145, 0),
      ),*/
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('messages').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text(
              'No messages found.',
              style: TextStyle(fontSize: 18, color: Colors.black),
            ));
          }

          final messages = snapshot.data!.docs
              .map((doc) => AdminMessage.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  ))
              .toList();

          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                elevation: 3,
                child: ListTile(
                  title: Text(message.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email: ${message.email}'),
                      const SizedBox(height: 8),
                      Text(message.message),
                      const SizedBox(height: 8),
                      //Text(
                      //  'Sent at: ${DateFormat('yyyy-MM-dd – kk:mm').format(message.timestamp.toDate())}', // Call toDate() here
                      // style:
                      //    const TextStyle(fontSize: 12, color: Colors.grey),
                      // ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.reply, color: Colors.blue),
                        onPressed: () =>
                            _replyToMessage(message.email, context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteMessage(message.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// AdminMessage class for handling messages received by admin
class AdminMessage {
  final String id;
  final String name;
  final String email;
  final String message;
  // final Timestamp timestamp;

  AdminMessage({
    required this.id,
    required this.name,
    required this.email,
    required this.message,
    //  required this.timestamp,
  });

  // Convert AdminMessage object to a map for database storage or serialization
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'message': message,
      // 'timestamp': timestamp, // Store as Timestamp
    };
  }

  // Convert a map to an AdminMessage object for retrieval from storage
  factory AdminMessage.fromMap(Map<String, dynamic> map, String id) {
    return AdminMessage(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      message: map['message'] ?? '',
      //timestamp: map['timestamp'] as Timestamp,
    );
  }
}
