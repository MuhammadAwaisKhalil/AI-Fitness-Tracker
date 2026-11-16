import 'package:flutter/material.dart';

/// Placeholder UI for Auth Feature
/// Future: Login / Registration UI that passes user credentials to the FastAPI backend.
class AuthScreen extends StatelessWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Auth Module Placeholder (Handled by FastAPI)'),
      ),
    );
  }
}

