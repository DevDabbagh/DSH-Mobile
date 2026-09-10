import 'package:flutter/material.dart';
import 'package:dsh_mobile/app/widgets/custom_button.dart';

class ExampleCustomButtonUsage extends StatelessWidget {
  final bool isValid;
  final VoidCallback onSubmit;

  const ExampleCustomButtonUsage({
    super.key, 
    required this.isValid,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: "Submit",
      // Switch between active gradient and inactive grey based on validation
      type: isValid ? CustomButtonType.primaryGradient : CustomButtonType.primaryGrey,
      // Only execute callback if valid
      onPressed: isValid ? onSubmit : () {}, 
    );
  }
}
