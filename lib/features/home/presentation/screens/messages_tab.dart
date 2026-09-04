import 'package:flutter/material.dart';
import '../../../chat/presentation/screens/conversations_screen.dart';

class MessagesTab extends StatelessWidget {
  const MessagesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const ConversationsScreen(isShelter: false);
  }
}
