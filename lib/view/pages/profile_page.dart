import 'package:cloud_firestore/cloud_firestore.dart'; // Firebase Firestore for database operations
import 'package:flutter/material.dart'; // Flutter Material package for UI components
import 'package:faculty_load/core/constants/colors.dart'; // Custom color constants
import 'package:faculty_load/helper/modal.dart'; // Helper class for modal utilities (e.g., snackbar)
import 'package:faculty_load/models/user_data.dart'; // User data model

// ProfilePage StatefulWidget: A screen to display and edit the profile of a user
class ProfilePage extends StatefulWidget {
  final String uid; // User ID passed to this page

  ProfilePage({required this.uid}); // Constructor to initialize the UID

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

// State class for ProfilePage
class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>(); // Global key for the form validation
  UserData _userData = UserData(name: '', email: '', role: '', type: ''); // Default user data object
  TextEditingController name = TextEditingController(); // Controller for the name input field
  TextEditingController email = TextEditingController(); // Controller for the email input field

  @override
  void initState() {
    // Initialize state and load user data on page load
    super.initState();
    print("######################");
    print(widget.uid); // Debugging log to verify the passed UID
    print("######################");
    _loadUserData(); // Call to load the user data from Firestore
  }

  // Function to load user data from Firestore based on the provided UID
  Future<void> _loadUserData() async {
    var snapshot = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
    if (snapshot.exists) {
      setState(() {
        _userData = UserData.fromMap(snapshot.data()!); // Parse Firestore data into a UserData object
        name.text = _userData.name; // Populate name field with user data
        email.text = _userData.email; // Populate email field with user data
      });
    }
  }

  // Function to save updated user data back to Firestore
  Future<void> _saveUserData() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save(); // Trigger save callbacks for form fields
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).update(_userData.toMap());
      Modal().snack(context, message: "Profile updated successfully!"); // Show a success message
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'), // AppBar title
        backgroundColor: mainColor, // Custom background color
        foregroundColor: Colors.white, // Text/icon color
      ),
      body: Form(
        key: _formKey, // Assign the form key
        child: ListView(
          padding: EdgeInsets.all(16.0), // Padding for the form
          children: <Widget>[
            // Name input field
            TextFormField(
              controller: name, // Controller to manage the name field
              decoration: InputDecoration(labelText: 'Name'), // Label for the input
              onSaved: (value) => _userData.name = value!, // Save the name value to the UserData object
              // Add validation if needed (e.g., required field)
            ),
            // Email input field
            TextFormField(
              controller: email, // Controller to manage the email field
              decoration: InputDecoration(labelText: 'Email'), // Label for the input
              onSaved: (value) => _userData.email = value!, // Save the email value to the UserData object
              // Add validation if needed (e.g., email format)
            ),
            SizedBox(
              height: 15, // Add spacing before the button
            ),
            // Save Changes button
            ElevatedButton(
              onPressed: _saveUserData, // Call the save function when pressed
              child: Text('Save Changes'), // Button label
            ),
          ],
        ),
      ),
    );
  }
}
