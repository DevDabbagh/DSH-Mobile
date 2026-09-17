/// "Be the first to know." — Figma 2266:1219.
///
/// Name, email, and what the person works on, then a gradient button.
///
/// THE FORM ACTUALLY SUBSCRIBES
///
/// It calls `newsletter_subscribe`, the same SECURITY DEFINER function the
/// website uses (migration 014). The table itself is closed to the public —
/// no select, no insert — so the RPC is the only way in, and the grant to
/// `anon` means a reader who has not signed in can still use this.
///
/// Two consequences worth knowing:
///
///   · The row lands as `pending`, not `subscribed`. Double opt-in: nobody is
///     on the list until they click the link in the confirmation email. So the
///     success message says to check their inbox rather than "you're in",
///     which would be a lie in the window that matters.
///   · It reports success for an address already on the list. That is
///     deliberate in the function — a "you're already subscribed" reply turns
///     this into a way for anyone to test whether a given person reads DSH —
///     so this screen must not try to be more informative than it is.
///
/// The name and the "what do you work on" answer have nowhere to go: the
/// table stores an email, a status and consent evidence, and no columns for
/// either. Rather than collect them and drop them on the floor, the work
/// answer is folded into `source` — which is a free-text provenance column
/// and the honest place for "who said they were" — and the name is asked for
/// but only used to address the person on screen. See the note below.
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/layers/academy/presentation/widgets/academy_atoms.dart';

/// The wording the person agrees to. Stored with the row, because if a
/// subscriber ever complains, the defence is the exact text they saw — and
/// reconstructing that after the fact is impossible.
const _kConsentText =
    'Academy tab: New courses, open calls, and workshops — straight to you.';

class AcademyNewsletterCard extends StatefulWidget {
  const AcademyNewsletterCard({super.key});

  @override
  State<AcademyNewsletterCard> createState() => _AcademyNewsletterCardState();
}

class _AcademyNewsletterCardState extends State<AcademyNewsletterCard> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _work = TextEditingController();

  bool _sending = false;
  String? _error;
  bool _done = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _work.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();

    // The same shape the RPC enforces. Checked here too so a typo is a
    // sentence under the field rather than a Postgres exception in a snackbar.
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _error = 'That email address does not look right.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      await Supabase.instance.client.rpc(
        'newsletter_subscribe',
        params: {
          'p_email': email,
          // Provenance plus what they told us they do. The column is free
          // text and documented as "where the address came from", so this
          // fits it rather than bending it.
          'p_source': _sourceLabel(),
          'p_consent_text': _kConsentText,
          // Deliberately empty. The function takes an IP for consent
          // evidence; an app has no trustworthy way to know its own public
          // address, and the ones it could guess are the device's LAN
          // address, which is evidence of nothing. Better a blank field than
          // a confident wrong one in a record whose whole purpose is proof.
          'p_consent_ip': '',
        },
      );

      if (!mounted) return;
      setState(() {
        _sending = false;
        _done = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = 'Could not sign you up just now. Please try again.';
      });
      debugPrint('[academy] newsletter_subscribe failed: $e');
    }
  }

  String _sourceLabel() {
    final work = _work.text.trim();
    return work.isEmpty ? 'mobile_academy' : 'mobile_academy: $work';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 24.h),
      decoration: BoxDecoration(
        color: const Color(0xFF101010).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(
          color: AppColors.smoke.withValues(alpha: 0.10),
          width: 1.2,
        ),
      ),
      child: _done ? _thanks() : _form(),
    );
  }

  Widget _thanks() {
    final name = _name.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.mark_email_read_outlined,
                size: 18.w, color: AppColors.mainBlue),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                name.isEmpty ? 'Almost there.' : 'Almost there, $name.',
                style: TextStyle(
                  color: AppColors.smoke,
                  fontSize: 16.sp,
                  height: 1.5,
                  letterSpacing: -0.3,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        Text(
          // Says what actually happened. The row is `pending` until the link
          // is clicked, so "you're subscribed" would be untrue right now.
          'Check your inbox and confirm — we only add you once you do.',
          style: TextStyle(
            color: AppColors.smoke.withValues(alpha: 0.35),
            fontSize: 12.sp,
            height: 1.42,
          ),
        ),
      ],
    );
  }

  Widget _form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Be the first to know.',
          style: TextStyle(
            color: AppColors.smoke,
            fontSize: 16.sp,
            height: 1.5,
            letterSpacing: -0.3,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'New courses, open calls, and workshops — straight to you.',
          style: TextStyle(
            color: AppColors.smoke.withValues(alpha: 0.35),
            fontSize: 12.sp,
            height: 1.42,
          ),
        ),
        SizedBox(height: 18.h),
        _Field(controller: _name, hint: 'Your name'),
        SizedBox(height: 8.h),
        _Field(
          controller: _email,
          hint: 'Email',
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
        ),
        SizedBox(height: 8.h),
        _Field(
          controller: _work,
          hint: 'What do you work on? (film, journalism, activism…)',
        ),
        if (_error != null) ...[
          SizedBox(height: 10.h),
          Text(
            _error!,
            style: TextStyle(color: AppColors.errorMain, fontSize: 11.sp),
          ),
        ],
        SizedBox(height: 12.h),
        if (_sending)
          SizedBox(
            height: 44.h,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.mainBlue,
                ),
              ),
            ),
          )
        else
          AcademyGradientButton(
            label: 'Register interest',
            onTap: _submit,
          ),
        SizedBox(height: 10.h),
        Text(
          "We don't share your data.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.smoke.withValues(alpha: 0.2),
            fontSize: 10.sp,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;

  const _Field({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      style: TextStyle(color: AppColors.smoke, fontSize: 13.sp),
      cursorColor: AppColors.mainBlue,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.academyMuted,
          fontSize: 13.sp,
        ),
        filled: true,
        fillColor: AppColors.smoke.withValues(alpha: 0.04),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        border: _border(AppColors.smoke.withValues(alpha: 0.10)),
        enabledBorder: _border(AppColors.smoke.withValues(alpha: 0.10)),
        focusedBorder: _border(AppColors.mainBlue, width: 1.2),
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 0.6}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(6.r),
        borderSide: BorderSide(color: color, width: width),
      );
}
