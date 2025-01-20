import 'package:flutter/material.dart';

class Modal {
  void showAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Alert'),
          content: Text('This is an alert dialog.'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  void show(BuildContext context, {title = "FlutterFire", message = "", ok = "OK", func = ""}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text(ok),
              onPressed: func != ""
                  ? func()
                  : () {
                      Navigator.pop(context);
                    },
            ),
          ],
        );
      },
    );
  }

  void confirm(BuildContext context, {title = "FlutterFire", message = "", ok = "OK", cancel = "Cancel", func = ""}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text(cancel),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text(ok),
              onPressed: () {
                if (func != "") {
                  func();
                }

                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void snack(BuildContext context, {message = "FlutterFire"}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}
