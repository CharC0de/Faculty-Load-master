// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:faculty_load/core/constants/colors.dart';
import 'package:faculty_load/data/firestore_helper.dart';
import 'package:faculty_load/view/pages/users/users_edit_page.dart';
import 'package:faculty_load/widgets/text_field.dart';

import '../../../models/user_data.dart';

// Main UsersPage widget, responsible for displaying users in a list
class UsersPage extends StatefulWidget {
  final String uid; // User ID of the logged-in user
  final String role; // Role of the logged-in user

  // Constructor for passing necessary data to the page
  UsersPage({required this.uid, required this.role});

  @override
  _UsersPageState createState() => _UsersPageState();
}

// State class for managing the state and UI logic of UsersPage
class _UsersPageState extends State<UsersPage> {
  FirestoreHelper fh = FirestoreHelper(); // Instance of FirestoreHelper for Firestore operations
  UserData _userData = UserData(name: '', email: '', role: '', type: ''); // User data to be loaded
  TextEditingController search = TextEditingController(); // Controller for search input

  // Initializes the state and loads the user data from Firestore
  @override
  void initState() {
    super.initState();
    _loadUserData();
    search.addListener(updateSearch); // Updates search results when search text changes
  }

  // Fetches user data from Firestore based on user ID
  Future<void> _loadUserData() async {
    var snapshot = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();

    // If the user exists, map the snapshot data to UserData object
    if (snapshot.exists) {
      setState(() {
        _userData = UserData.fromMap(snapshot.data()!);
      });
    }
  }

  // Placeholder method for adding a new user (currently commented out)
  void _handleAdd() {
    // Navigator.push(context, MaterialPageRoute(builder: (context) => AddUserPage(uid: widget.uid)));
  }

  // Handles deleting a user by user ID
  Future _handleDelete(String userId) async {
    try {
      await fh.deleteItem(userId, 'users'); // Deletes user from the Firestore collection 'users'
    } catch (e) {
      print('Error deleting user: $e'); // Catches and prints errors during deletion
    }
  }

  // Updates the UI when the search text changes
  void updateSearch() {
    setState(() {}); // Triggers a UI rebuild when search text is updated
  }

  // Builds the main UI of the UsersPage
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Faculties'), // AppBar title
        backgroundColor: mainColor, // AppBar background color
        foregroundColor: Colors.white, // AppBar text color
      ),
      body: Column(
        children: [
          // Search input field
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: MyTextField(
              controller: search, // The search TextEditingController
              width: double.infinity, // Full-width for the search field
              hintText: "Search name", // Placeholder text for the search field
            ),
          ),
          // Expanded widget to take up remaining space in the body
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: fh.streamWithAttributes('users', {}), // Fetches real-time data of users from Firestore
              builder: (context, snapshot) {
                // Handling different states of the StreamBuilder
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Text(
                      'No data available', // Loading state message
                      style: TextStyle(
                        fontSize: 18.0,
                        color: Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Something went wrong!', // Error message
                      style: TextStyle(
                        fontSize: 18.0,
                        color: Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                } else {
                  // If data is available, process the snapshot data
                  var usersLists = snapshot.data!.docs;
                  var usersList = [];

                  // Filtering users based on search text and excluding admins
                  for (var u in usersLists) {
                    var tmp = u.data() as Map<String, dynamic>;
                    var n = tmp['name'] ?? "";

                    // Only include users whose names match the search input
                    if (n.toLowerCase().contains(search.text.toLowerCase())) {
                      usersList.add(u);
                    }

                    // Remove 'admin' users from the list
                    if (tmp['role'] == 'admin') {
                      usersList.remove(u);
                    }
                  }

                  // Building the list view for users
                  return ListView.builder(
                    itemCount: usersList.length, // Number of users in the filtered list
                    itemBuilder: (context, index) {
                      final userData = usersList[index].data() as Map<String, dynamic>;
                      final userId = usersList[index].id;
                      userData['id'] = userId; // Adding user ID to the data
                      final email = userData['email'] ?? '';
                      final name = userData['name'] ?? '';

                      // Returning a list tile for each user
                      return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.withOpacity(0.5),
                              width: 1.0, // Bottom border of the tile
                            ),
                          ),
                        ),
                        child: ListTile(
                          subtitle: Text(email), // Displaying email as subtitle
                          title: GestureDetector(
                            onTap: () {}, // Placeholder onTap action for name (currently does nothing)
                            child: Text('$name'), // Displaying user's name
                          ),
                          trailing: GestureDetector(
                            onTap: () {
                              // Navigating to the EditUserPage to edit the user's details
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => EditUserPage(
                                    userId: userId, // Passing user ID to the edit page
                                    uid: widget.uid, // Passing logged-in user ID
                                  ),
                                ),
                              );
                            },
                            child: Icon(
                              Icons.edit, // Edit icon
                              color: mainColor, // Icon color
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
