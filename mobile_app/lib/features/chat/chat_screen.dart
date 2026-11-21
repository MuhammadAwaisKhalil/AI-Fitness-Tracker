import 'package:flutter/material.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

/// Offline conversational AI Fitness & Biomechanics Coach.
/// Provides immediate, intelligent answers for workout form, routine planning,
/// cardio pacing, and nutrition advice.
class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  final List<String> _quickPrompts = [
    'How do I fix my squat depth?',
    'Tips to stop sagging during push-ups',
    'Best cardio routine for fat loss',
    'How long should I hold a plank?',
    'What should I eat post-workout?',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        text:
            'Hello! I am your AI Biomechanics & Performance Coach. Ask me anything about your exercise form, tempo, cardio pacing, or nutrition plan!',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final userMsg = text.trim();
    _controller.clear();

    setState(() {
      _messages.add(
        ChatMessage(text: userMsg, isUser: true, timestamp: DateTime.now()),
      );
      _isTyping = true;
    });

    _scrollToBottom();

    // Simulate intelligent coach reply with realistic delay
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final reply = _generateCoachReply(userMsg);
      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(text: reply, isUser: false, timestamp: DateTime.now()),
        );
      });
      _scrollToBottom();
    });
  }

  String _generateCoachReply(String prompt) {
    final lower = prompt.toLowerCase();

    if (lower.contains('squat')) {
      return 'For deep squats: Keep your feet shoulder-width apart with toes flared out 15-30°. Initiate the descent by sending your hips back first, driving knees outward over your toes. Ensure your femur reaches parallel (below 100° knee angle) while keeping your chest proud and spine neutral.';
    } else if (lower.contains('push-up') || lower.contains('pushup')) {
      return 'Push-up form tip: Keep your body as a rigid plank (shoulder-hip-ankle angle > 155°). Do not let your lower back sag. Angle your elbows back at roughly 45° to protect your shoulder rotator cuffs, and lower until your chest is 2-3 inches off the ground.';
    } else if (lower.contains('plank') || lower.contains('core')) {
      return 'Plank biomechanics: Avoid piking your hips up or letting them droop toward the floor. Actively squeeze your glutes, press into your forearms to fill your upper back, and breathe steadily. Aim for 3-4 sets of 45-60 second holds with crisp alignment.';
    } else if (lower.contains('cardio') || lower.contains('jumping jack') || lower.contains('fat loss')) {
      return 'Cardio strategy: High-intensity interval training (HIIT) with jumping jacks and high knees accelerates calorie burn and boosts VO2 max. Aim for 30s max effort followed by 20s active rest for 8-10 rounds!';
    } else if (lower.contains('eat') || lower.contains('food') || lower.contains('protein') || lower.contains('nutrition')) {
      return 'Post-workout fuel: Consume 25-35g of fast-digesting protein alongside complex carbohydrates within 45-60 minutes post-session to optimize muscle protein synthesis and replenish glycogen stores.';
    } else if (lower.contains('shoulder') || lower.contains('press')) {
      return 'Shoulder Press: Keep your core braced and ribs tucked down so you do not hyper-extend your lumbar spine. Press the weights straight overhead until your elbows reach 160°+ extension with bicep near your ear.';
    } else {
      return 'Great question! In fitness and biomechanics, consistency and controlled tempo always beat reckless volume. Focus on strict form, track your reps on the Workout screen, and refuel with adequate protein!';
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF00E5FF),
              child: Icon(Icons.psychology, color: Colors.black, size: 20),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Biomechanics Coach',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Real-time Form & Performance AI',
                  style: TextStyle(fontSize: 11, color: Color(0xFF76FF03)),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Quick Prompts Chips
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _quickPrompts.length,
              itemBuilder: (context, index) {
                final prompt = _quickPrompts[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    backgroundColor: const Color(0xFF1E1E1E),
                    side: const BorderSide(color: Colors.white12),
                    label: Text(
                      prompt,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF00E5FF)),
                    ),
                    onPressed: () => _sendMessage(prompt),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1, color: Colors.white10),

          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          if (_isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF00E5FF),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Coach is analyzing biomechanics...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          // Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Ask about form, reps, tempo...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: Color(0xFF00E5FF)),
                    onPressed: () => _sendMessage(_controller.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: msg.isUser ? const Color(0xFF00E5FF) : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 16),
          ),
          border: Border.all(
            color: msg.isUser ? Colors.transparent : Colors.white12,
          ),
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: msg.isUser ? Colors.black : Colors.white,
            fontSize: 14,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}
