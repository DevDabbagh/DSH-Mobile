import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dsh_mobile/app/config/app_colors.dart';

class CustomTextField extends StatefulWidget {
  final String hintText;
  final IconData? prefixIcon;
  final String? prefixIconPath;
  final bool isPassword;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final List<TextInputFormatter>? inputFormatters;

  /// Lets the screen above move focus on "next" — the sign-in and sign-up
  /// forms chain their fields, and without a handle on the next field the
  /// keyboard's next key simply dismissed the keyboard.
  final FocusNode? focusNode;

  /// iOS and Android password managers only offer to fill a field that says
  /// what it holds. Without this, a saved DSH password is invisible to the
  /// keychain and the user types it by hand every time.
  final Iterable<String>? autofillHints;

  const CustomTextField({
    super.key,
    required this.hintText,
    this.prefixIcon,
    this.prefixIconPath,
    this.isPassword = false,
    this.controller,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onFieldSubmitted,
    this.inputFormatters,
    this.focusNode,
    this.autofillHints,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      autofillHints: widget.autofillHints,
      obscureText: widget.isPassword ? _obscureText : false,
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      inputFormatters: widget.inputFormatters,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: widget.prefixIconPath != null
            ? Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: SvgPicture.asset(
                  widget.prefixIconPath!,
                  width: 20.sp,
                  height: 20.sp,
                  colorFilter: const ColorFilter.mode(
                      Color(0xFF717171), BlendMode.srcIn),
                  fit: BoxFit.contain,
                ),
              )
            : widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    color: const Color(0xFF717171),
                    size: 20.sp,
                  )
                : null,
        prefixIconConstraints: BoxConstraints(
          minWidth: 48.w,
          minHeight: 48.h,
        ),
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.textMuted,
                  size: 20.sp,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : null,
      ),
    );
  }
}
