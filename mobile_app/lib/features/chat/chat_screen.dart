import 'package:flutter/material.dart';

/// Placeholder UI for Chat Feature
/// Future: Chat interface that streams conversational responses from the FastAPI LLM service.
class ChatScreen extends StatelessWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Chat Module Placeholder (Streamed from FastAPI)'),
      ),
    );
  }
}

