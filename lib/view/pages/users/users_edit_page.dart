import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:faculty_load/core/constants/colors.dart';
import 'package:faculty_load/helper/modal.dart';

import '../../../data/firestore_helper.dart';

// EditUserPage allows users to edit the details of a specific user
class EditUserPage extends StatefulWidget {
  final String uid; // User ID of the logged-in user
  final String userId; // ID of the user to be edited

  const EditUserPage({
    super.key,
    required this.uid,
    required this.userId,
  });

  @override
  _EditUserPageState createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); // Form key to validate the form
  final TextEditingController _emailController = TextEditingController(); // Controller for email input field
  final TextEditingController _nameController = TextEditingController(); // Controller for name input field
  FirestoreHelper fh = FirestoreHelper(); // Helper class for Firestore operations
  bool isLoading = false; // Flag to show loading state during data fetching or updating
  String? _selectedRole; // Variable to store selected role (e.g., teacher, admin)
  String? _selectedStatus; // Variable to store selected status (e.g., Active, Inactive)

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Load user data when the page is initialized
  }

  // Function to fetch user data from Firestore
  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true; // Set loading state to true while data is being fetched
    });

    try {
      // Fetch the user data from Firestore
      final userSnapshot = await fh.readItem(widget.userId, 'users');
      if (userSnapshot.exists) {
        setState(() {
          // Populate the form with the fetched user data
          _emailController.text = userSnapshot['email'] ?? '';
          _nameController.text = userSnapshot['name'] ?? '';
          _selectedRole = userSnapshot['role'] ?? 'teacher'; // Default to 'teacher'
          _selectedStatus = userSnapshot['status'] ?? 'Inactive'; // Default to 'Inactive'
        });
      }
    } catch (e) {
      print('Error loading user data: $e'); // Log the error if fetching data fails
      Modal().snack(context, message: "Failed to load user data."); // Show an error message
    }

    setState(() {
      isLoading = false; // Set loading state to false after data fetching completes
    });
  }

  // Function to handle form submission
  void _submitForm() async {
    setState(() {
      isLoading = true; // Set loading state to true while updating user data
    });

    if (_formKey.currentState!.validate()) {
      // Only proceed if form is valid
      final Map<String, dynamic> userData = {
        'uid': widget.uid, // User ID of the logged-in user
        'email': _emailController.text, // Updated email
        'name': _nameController.text, // Updated name
        'role': _selectedRole, // Selected role
        'status': _selectedStatus, // Selected status
      };

      try {
        // Update the user data in Firestore
        await fh.updateItem(widget.userId, userData, 'users');
        Modal().snack(context, message: "User successfully updated!"); // Show success message
        Navigator.pop(context); // Go back to the previous screen
      } catch (e) {
        // Handle any errors that occur during the update process
        print('Error updating user: $e');
        Modal().snack(context, message: "Failed to update user."); // Show error message
      }
    }

    setState(() {
      isLoading = false; // Set loading state to false after the update process is complete
    });
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Container(
            color: mainColor, // Show a loading spinner while data is being fetched or updated
            child: const Center(
              child: SpinKitFadingCube(
                color: Colors.white, // Fading cube spinner
              ),
            ),
          )
        : Scaffold(
            appBar: AppBar(
              title: const Text('Edit User'), // AppBar title
              backgroundColor: mainColor,
              foregroundColor: Colors.white,
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey, // Form key to validate the form
                  child: Column(
                    children: <Widget>[
                      // Email field (read-only)
                      TextFormField(
                        controller: _emailController,
                        readOnly: true,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter an email'; // Validation for empty email
                          }
                          return null;
                        },
                      ),
                      // Name field (read-only)
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                        readOnly: true,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter a name'; // Validation for empty name
                          }
                          return null;
                        },
                      ),
                      // Dropdown for selecting the user's role
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: const InputDecoration(labelText: 'Role'),
                        items: ['teacher', 'admin']
                            .map((role) => DropdownMenuItem<String>(
                                  value: role,
                                  child: Text(role),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value; // Update selected role
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a role'; // Validation for missing role
                          }
                          return null;
                        },
                      ),
                      // Dropdown for selecting the user's status
                      DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: ['1', '0']
                            .map((status) => DropdownMenuItem<String>(
                                  value: status,
                                  child: Text(status == '1' ? 'Active' : 'Inactive'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value; // Update selected status
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a status'; // Validation for missing status
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),
                      // Button to submit the form
                      ElevatedButton(
                        onPressed: _submitForm, // Call _submitForm when pressed
                        child: const Text('Update User'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
  }
}
