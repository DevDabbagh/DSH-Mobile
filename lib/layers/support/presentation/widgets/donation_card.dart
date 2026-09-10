import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/layers/support/data/repositories/donations_repository_impl.dart';
import 'package:dsh_mobile/layers/support/domain/entities/donation.dart';
import 'package:dsh_mobile/layers/support/presentation/checkout_webview_page.dart';
import 'package:dsh_mobile/layers/support/presentation/controllers/donation_controller.dart';
import 'package:dsh_mobile/layers/support/presentation/widgets/donation_thanks_dialog.dart';
import 'package:dsh_mobile/layers/support/presentation/widgets/funded_project_card.dart';

/// The donation card — the one part of this screen that is NOT editable.
///
/// Amounts, the monthly toggle and the checkout button are behaviour, not
/// copy. The dashboard can rewrite every word on the Support page without
/// being able to break a payment; that is deliberate and matches the web.
///
/// There are no plan tiers. Monthly or one-time, and an amount — naming ranks
/// ("Supporter", "Patron") would sort donors, which DSH does not want to do.
class DonationCard extends ConsumerWidget {
  final FundingTarget? target;
  const DonationCard({super.key, this.target});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(donationFormProvider);
    final controller = ref.read(donationFormProvider.notifier);
    final isTest = ref.watch(stripeTestModeProvider).valueOrNull;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(
          color: AppColors.smoke.withValues(alpha: 0.10),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (target != null) FundedProjectCard(target!),

          _ModeToggle(
            mode: form.mode,
            onChanged: controller.setMode,
          ),
          SizedBox(height: 20.h),

          // Centred, the way the Figma frame heads its amount row. The mode
          // toggle above already says what kind of gift this is, so this line
          // only has to say "pick a number".
          Center(
            child: Text(
              form.mode == DonationMode.monthly
                  ? 'Choose a monthly amount'
                  : 'Choose an amount',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: 14.h),

          // Pills, wrapped rather than a fixed row: four presets plus Custom
          // is five controls, and five on one line on a 360 dp phone leaves
          // "€100" one pixel wide.
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                for (final preset in kDonationPresets)
                  _AmountChip(
                    label: '€$preset',
                    selected: form.preset == preset,
                    onTap: () => controller.selectPreset(preset),
                  ),
                _AmountChip(
                  label: 'Custom',
                  // "No preset chosen" and "typing your own" are the same
                  // state in the controller, and that is what makes the pair
                  // safe: exactly one control can ever look selected, so the
                  // number on the button is always the number that will be
                  // taken.
                  selected: form.preset == null,
                  onTap: () => controller.setCustom(form.custom),
                ),
              ],
            ),
          ),

          // Only once Custom is chosen. An always-visible second input beside
          // a selected preset is the fastest way to make a donor unsure which
          // amount is about to be charged.
          if (form.preset == null) ...[
            SizedBox(height: 12.h),
            _CustomAmountField(
              active: true,
              value: form.custom,
              onChanged: controller.setCustom,
            ),
          ],

          if (isTest == true) ...[
            SizedBox(height: 14.h),
            Text(
              'Test mode — no payment will be taken.',
              style: TextStyle(
                color: AppColors.warningMain,
                fontSize: 11.sp,
              ),
            ),
          ],

          if (form.error != null) ...[
            SizedBox(height: 14.h),
            Text(
              form.error!,
              style: TextStyle(color: AppColors.errorMain, fontSize: 12.sp),
            ),
          ],

          SizedBox(height: 18.h),
          _GiveButton(
            state: form,
            onPressed: () => _startCheckout(context, ref),
          ),
          SizedBox(height: 10.h),

          Text(
            'Payment is handled by Stripe, in your browser. '
            'A monthly gift can be cancelled by you at any time.',
            style: TextStyle(
              color: AppColors.mediumGrey,
              fontSize: 10.sp,
              height: 15 / 10,
            ),
          ),
        ],
      ),
    );
  }

  /// Opens Stripe Checkout inside the app and handles what comes back.
  ///
  /// The whole point of keeping it in-app is this method's second half: a
  /// donor sent out to a browser has to find their way back, and most simply
  /// close the tab — so the gift lands, and they are never thanked for it.
  /// Here the return is a navigation the checkout view can see, so control
  /// comes back to us automatically and the thank-you follows.
  ///
  /// Note what happens on `dismissed`: the donor closed the view themselves,
  /// which is NOT proof that nothing was paid — the payment may have gone
  /// through a moment earlier and the redirect been beaten by the swipe.
  /// Treating "they closed it" as "they didn't pay" would swallow a real
  /// donation, so we ask the server about the session we created rather than
  /// assuming. The dialog handles an unpaid session on its own, and says
  /// nothing was taken.
  ///
  /// Only an outright cancel is taken at face value: that is Stripe telling
  /// us, not a guess about a gesture.
  Future<void> _startCheckout(BuildContext context, WidgetRef ref) async {
    final session =
        await ref.read(donationFormProvider.notifier).startCheckout(target);
    if (session == null) return; // the card is already showing why
    if (!context.mounted) return;

    final outcome = await Navigator.of(context).push<CheckoutOutcome>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CheckoutWebViewPage(checkoutUrl: session.url),
      ),
    );

    if (!context.mounted) return;
    ref.read(donationFormProvider.notifier).reset();

    // Cancelled: the donor chose to stop. Say nothing — "your donation was
    // cancelled" reads as an accusation.
    if (outcome?.status == CheckoutStatus.cancelled) return;

    if (outcome?.status == CheckoutStatus.success &&
        outcome?.sessionId != null) {
      await DonationThanksDialog.show(context, outcome!.sessionId!);
      return;
    }

    // Dismissed. Check quietly before deciding there is nothing to say: if
    // they did pay, thank them; if they didn't, they get no dialog at all,
    // because someone who backed out of a payment does not need to be told
    // they were not charged.
    if (session.id.isEmpty) return;

    final result =
        await ref.read(donationsRepositoryProvider).verifySession(session.id);

    if (!context.mounted) return;

    final paid = result.fold((_) => false, (receipt) => receipt.paid);
    if (paid) await DonationThanksDialog.show(context, session.id);
  }
}

/* ── monthly / one-time ─────────────────────────────────────────────── */

class _ModeToggle extends StatelessWidget {
  final DonationMode mode;
  final ValueChanged<DonationMode> onChanged;
  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppColors.deepBackground,
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: _ModeTab(
                label: 'Monthly',
                selected: mode == DonationMode.monthly,
                onTap: () => onChanged(DonationMode.monthly),
              ),
            ),
            Expanded(
              child: _ModeTab(
                label: 'One-time',
                selected: mode == DonationMode.oneTime,
                onTap: () => onChanged(DonationMode.oneTime),
              ),
            ),
          ],
        ),
      );
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: selected ? AppColors.purpleDark1 : Colors.transparent,
            borderRadius: BorderRadius.circular(3.r),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? AppColors.smoke : AppColors.mediumGrey,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
}

/* ── amounts ────────────────────────────────────────────────────────── */

class _AmountChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _AmountChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 11.h, horizontal: 20.w),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.darkBackground
                : AppColors.darkBackground.withValues(alpha: 0.4),
            // Fully rounded, per the Figma frame — the amounts are the one
            // place on this screen the design softens, and it is what tells
            // a donor they are choices rather than fields.
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppColors.smoke
                  : AppColors.smoke.withValues(alpha: 0.14),
              width: selected ? 1.2 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? AppColors.white : AppColors.lightGrey,
              fontSize: 14.sp,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      );
}

/// The "other amount" box.
///
/// Stateful on purpose. The field is driven by controller state — selecting a
/// preset must clear it — but rebuilding a `TextEditingController` inside
/// `build` would reset the caret to the start on every keystroke, so the
/// controller is owned here and only written to when the value actually
/// diverges from what the user typed.
class _CustomAmountField extends StatefulWidget {
  final bool active;
  final String value;
  final ValueChanged<String> onChanged;
  const _CustomAmountField({
    required this.active,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_CustomAmountField> createState() => _CustomAmountFieldState();
}

class _CustomAmountFieldState extends State<_CustomAmountField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(covariant _CustomAmountField old) {
    super.didUpdateWidget(old);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get active => widget.active;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: active
              ? AppColors.purpleDark1
              : AppColors.darkBackground.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(3.r),
          border: Border.all(
            color: active
                ? AppColors.mainPurple
                : AppColors.smoke.withValues(alpha: 0.10),
          ),
        ),
        child: Row(
          children: [
            Text(
              '€',
              style: TextStyle(
                color: active ? AppColors.smoke : AppColors.mediumGrey,
                fontSize: 15.sp,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: widget.onChanged,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                cursorColor: AppColors.mainPurple,
                style: TextStyle(color: AppColors.smoke, fontSize: 15.sp),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                  hintText: 'Other amount',
                  hintStyle: TextStyle(
                    color: AppColors.mediumGrey,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

/* ── the button ─────────────────────────────────────────────────────── */

class _GiveButton extends StatelessWidget {
  final DonationFormState state;
  final VoidCallback onPressed;
  const _GiveButton({required this.state, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final amount = state.amount;
    // Disabled rather than hidden, and disabled rather than allowed to fail:
    // pressing through to a checkout that will 400 reads as a broken payment.
    final enabled = amount != null && !state.busy;

    final label = amount == null
        ? 'Choose an amount'
        : state.mode == DonationMode.monthly
            ? 'Give ${_money(amount)} monthly'
            : 'Give ${_money(amount)}';

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 15.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3.r),
            gradient: AppColors.primaryGradient,
          ),
          child: state.busy
              ? SizedBox(
                  height: 18.h,
                  child: const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                )
              : Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }

  /// €25 rather than €25.00; €12.50 keeps its cents.
  String _money(double v) =>
      v == v.roundToDouble() ? '€${v.toInt()}' : '€${v.toStringAsFixed(2)}';
}
