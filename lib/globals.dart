import 'package:flutter/material.dart';

class Globals {
  static GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void snackBarNotif(String message) {
    SnackBar snackBar = SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    );
    Globals.scaffoldMessengerKey.currentState?.showSnackBar(snackBar);
  }
}
