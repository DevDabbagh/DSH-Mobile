import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/layers/support/data/repositories/donations_repository_impl.dart';
import 'package:dsh_mobile/layers/support/domain/entities/donation.dart';

/// The thank-you, shown when the checkout view closes on a completed payment.
///
/// The same three states as the website's dialog, because it is the same
/// moment and the same decision:
///   · loading  — verifying the session (which also files the donation)
///   · asking   — thank you, plus "shall we put your name to this?"
///   · done     — confirmed, named or anonymous
///
/// **The gift is already recorded before this appears.** Verifying is what
/// records it. So this form only decides whose name is on it — closing the
/// dialog without answering loses nothing but the attribution, and the money
/// is safe either way. That is why there is no "are you sure?" on the close
/// button: nothing is at stake behind it.
///
/// Shown with [show], which returns once the donor is done.
class DonationThanksDialog extends ConsumerStatefulWidget {
  final String sessionId;

  const DonationThanksDialog({super.key, required this.sessionId});

  static Future<void> show(BuildContext context, String sessionId) =>
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.72),
        builder: (_) => DonationThanksDialog(sessionId: sessionId),
      );

  @override
  ConsumerState<DonationThanksDialog> createState() =>
      _DonationThanksDialogState();
}

class _DonationThanksDialogState extends ConsumerState<DonationThanksDialog> {
  final _name = TextEditingController();
  final _email = TextEditingController();

  DonationReceipt? _receipt;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  bool? _savedAnonymous;

  @override
  void initState() {
    super.initState();
    _verify();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final result = await ref
        .read(donationsRepositoryProvider)
        .verifySession(widget.sessionId);

    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _loading = false;
        _error = failure.message;
      }),
      (receipt) => setState(() {
        _loading = false;
        _receipt = receipt;
        // Stripe collected these during checkout; they are only a starting
        // point — the donor can change them or refuse them.
        if (receipt.email != null) _email.text = receipt.email!;
        if (receipt.name != null) _name.text = receipt.name!;
      }),
    );
  }

  Future<void> _save({required bool anonymous}) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final result = await ref.read(donationsRepositoryProvider).claimDonation(
          sessionId: widget.sessionId,
          anonymous: anonymous,
          name: anonymous ? null : _name.text.trim(),
          email: anonymous ? null : _email.text.trim(),
        );

    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _saving = false;
        _error = failure.message;
      }),
      (_) => setState(() {
        _saving = false;
        _savedAnonymous = anonymous;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        padding: EdgeInsets.all(22.w),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(
            color: AppColors.smoke.withValues(alpha: 0.12),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_body()],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const _Verifying();

    final receipt = _receipt;

    // Could not reach the server. The payment itself is unaffected — Stripe
    // took it and the webhook will file it — so this says so rather than
    // implying the gift failed.
    if (receipt == null) {
      return _Message(
        title: 'We could not confirm your payment',
        body: _error ??
            'If you were charged, your gift is safe and will be recorded. '
                'Nothing needs doing on your side.',
        onClose: () => Navigator.of(context).pop(),
      );
    }

    if (!receipt.paid) {
      return _Message(
        title: 'Nothing was taken',
        body: 'That payment was not completed, so you have not been charged.',
        onClose: () => Navigator.of(context).pop(),
      );
    }

    if (_savedAnonymous != null) {
      return _Message(
        title: 'Thank you',
        body: _savedAnonymous!
            ? 'Your gift is recorded anonymously.'
            : 'Your gift is recorded in your name.',
        onClose: () => Navigator.of(context).pop(),
      );
    }

    return _Ask(
      receipt: receipt,
      name: _name,
      email: _email,
      saving: _saving,
      error: _error,
      onName: () => _save(anonymous: false),
      onAnonymous: () => _save(anonymous: true),
      onClose: () => Navigator.of(context).pop(),
    );
  }
}

/* ── states ─────────────────────────────────────────────────────────── */

class _Verifying extends StatelessWidget {
  const _Verifying();

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: 24.h),
        child: Row(
          children: [
            SizedBox(
              width: 18.w,
              height: 18.w,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.mainPurple,
              ),
            ),
            SizedBox(width: 14.w),
            Text(
              'Confirming your gift…',
              style: TextStyle(color: AppColors.lightGrey, fontSize: 14.sp),
            ),
          ],
        ),
      );
}

class _Message extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback onClose;
  const _Message({
    required this.title,
    required this.body,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            body,
            style: TextStyle(
              color: AppColors.mediumGrey,
              fontSize: 13.sp,
              height: 20 / 13,
            ),
          ),
          SizedBox(height: 18.h),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onClose,
              child: Text(
                'Close',
                style: TextStyle(color: AppColors.mainPurple, fontSize: 14.sp),
              ),
            ),
          ),
        ],
      );
}

class _Ask extends StatelessWidget {
  final DonationReceipt receipt;
  final TextEditingController name;
  final TextEditingController email;
  final bool saving;
  final String? error;
  final VoidCallback onName;
  final VoidCallback onAnonymous;
  final VoidCallback onClose;

  const _Ask({
    required this.receipt,
    required this.name,
    required this.email,
    required this.saving,
    required this.error,
    required this.onName,
    required this.onAnonymous,
    required this.onClose,
  });

  String get _amount {
    final v = receipt.amount;
    final symbol = receipt.currency.toLowerCase() == 'eur'
        ? '€'
        : '${receipt.currency.toUpperCase()} ';
    return v == v.roundToDouble()
        ? '$symbol${v.toInt()}'
        : '$symbol${v.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final monthly = receipt.mode == DonationMode.monthly;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40.w,
          height: 2.h,
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        SizedBox(height: 14.h),
        Text(
          'Thank you.',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 22.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          receipt.projectTitle != null
              ? '$_amount${monthly ? ' a month' : ''} towards ${receipt.projectTitle}.'
              : '$_amount${monthly ? ' a month' : ''} towards the work.',
          style: TextStyle(
            color: AppColors.lightGrey,
            fontSize: 14.sp,
            height: 21 / 14,
          ),
        ),
        SizedBox(height: 18.h),
        Text(
          'Shall we put your name to it?',
          style: TextStyle(
            color: AppColors.smoke,
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 10.h),
        _Field(controller: name, hint: 'Name (optional)'),
        SizedBox(height: 8.h),
        _Field(
          controller: email,
          hint: 'Email',
          keyboardType: TextInputType.emailAddress,
        ),
        if (error != null) ...[
          SizedBox(height: 10.h),
          Text(
            error!,
            style: TextStyle(color: AppColors.errorMain, fontSize: 12.sp),
          ),
        ],
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: saving ? null : onName,
                behavior: HitTestBehavior.opaque,
                child: Opacity(
                  opacity: saving ? 0.5 : 1,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 13.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3.r),
                      gradient: AppColors.primaryGradient,
                    ),
                    child: Text(
                      'Save',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: GestureDetector(
                onTap: saving ? null : onAnonymous,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 13.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3.r),
                    border: Border.all(
                      color: AppColors.smoke.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text(
                    'Stay anonymous',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.lightGrey,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onClose,
            child: Text(
              'Not now',
              style: TextStyle(color: AppColors.mediumGrey, fontSize: 12.sp),
            ),
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
  const _Field({
    required this.controller,
    required this.hint,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: keyboardType,
        cursorColor: AppColors.mainPurple,
        style: TextStyle(color: AppColors.smoke, fontSize: 14.sp),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: AppColors.deepBackground,
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.mediumGrey, fontSize: 13.sp),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(3.r),
            borderSide: BorderSide(
              color: AppColors.smoke.withValues(alpha: 0.14),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(3.r),
            borderSide: BorderSide(
              color: AppColors.smoke.withValues(alpha: 0.14),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(3.r),
            borderSide: const BorderSide(color: AppColors.mainPurple),
          ),
        ),
      );
}
