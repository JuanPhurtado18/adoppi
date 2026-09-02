import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class MessagesTab extends StatelessWidget {
  const MessagesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: Text('Mensajes — Próximamente')),
    );
  }
}
