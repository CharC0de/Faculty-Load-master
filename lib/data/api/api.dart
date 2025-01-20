import 'package:firebase_auth/firebase_auth.dart';
import 'package:faculty_load/data/firestore_helper.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ApiClient extends GetConnect {
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  FirestoreHelper fh = FirestoreHelper();

  Future<User?> registerUser(String name, String email, String password, String academicRank, String contact, {String role = "faculty"}) async {
    User user;
    try {
      // Create a new user in Firebase using the email and password provided.
      final UserCredential userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get the newly created user's details.
      user = userCredential.user!;

      // Create a new user profile in Firebase that includes the name provided.
      await user.updateDisplayName(name);
      print("##########################");
      print(userCredential.user!.uid);
      var uid = userCredential.user!.uid;
      fh.createItemWithCustomID(
        uid,
        {
          "email": email,
          "name": name,
          "academic_rank": academicRank,
          "contact": contact,
          "role": role,
          "password": password,
        },
        "users",
      );
      // fh.createItemWithCustomID(
      //   uid,
      //   {
      //     "email": "consultant@gmail.com",
      //     "name": "Consultant",
      //     "role": "Consultant",
      //   },
      //   "users",
      // );
      print("##########################");

      // send verification email
      await user.sendEmailVerification();
    } catch (error) {
      // Handle any errors that occurred while creating the user or updating their profile.
      return null;
    }
    return user;
  }

  Future<User?> login(String email, String password) async {
    try {
      // Sign in to Firebase using the email and password provided.
      final UserCredential userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: email, //asd@asd.com,
        password: password, //password,
      );

      // Get the authenticated user's details.
      final User user = userCredential.user!;

      return user;
    } catch (error) {
      // Handle any errors that occurred during the login process.
      return null;
    }
  }

  Future<bool> reset(String email) async {
    try {
      // Send a password reset email to the user with the given email address.
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return true;
    } catch (error) {
      // Handle any errors that occurred while sending the password reset email.
      return false;
    }
  }

  Future<bool> change(String oldPassword, String newPassword) async {
    try {
      // Get the currently authenticated user from Firebase.
      final User user = firebaseAuth.currentUser!;

      // Update the user's password in Firebase using the old and new passwords provided.
      await user.updatePassword(newPassword);
      return true;
    } catch (error) {
      // Handle any errors that occurred while changing the user's password.
      return false;
    }
  }

  Future<void> logout() async {
    try {
      // Sign out the user from Firebase and clear any active user sessions.
      await firebaseAuth.signOut();
    } catch (error) {
      print(error);
    }
  }

  Future<User?> loginWithGoogle() async {
    try {
      // Create a new instance of the GoogleSignIn class.
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // Get the Google account that the user has signed in with.
      final GoogleSignInAccount? googleAccount = await googleSignIn.signIn();

      // Get the authentication credentials from the Google account.
      final GoogleSignInAuthentication googleAuth = await googleAccount!.authentication;

      // Create a new credential using the Google authentication credentials.
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase using the Google credential.
      final userCredential = await firebaseAuth.signInWithCredential(credential);
      final User user = userCredential.user!;
      return user;
    } catch (error) {
      // Handle any errors that occurred while signing in with Google.
      print(error);
      return null;
    }
  }
}
