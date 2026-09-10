import 'package:flutter/material.dart';
import 'package:dsh_mobile/app/config/app_colors.dart';

class AcademyPage extends StatelessWidget {
  const AcademyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.brandBlack,
      body:
          Center(child: Text('Academy', style: TextStyle(color: Colors.white))),
    );
  }
}
