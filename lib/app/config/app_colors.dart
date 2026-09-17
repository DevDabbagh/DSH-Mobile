import 'package:flutter/material.dart';

/// DSH Brand Colors — extracted from the Figma Design System.
class AppColors {
  AppColors._();

  // ── Neutrals ──
  static const Color black = Color(0xFF000000);

  /// The near-black the content screens sit on (Films/Studio tabs and their
  /// detail pages). Deliberately darker than [darkBackground] so the raised
  /// card surface reads as raised.
  static const Color deepBackground = Color(0xFF0D0D0D);

  /// Card fill on the content screens, used at 88% so the hero behind a card
  /// still shows through slightly.
  static const Color cardSurface = Color(0xFF131313);

  static const Color darkBackground = Color(0xFF1B1B1B);
  static const Color mediumBackground = Color(0xFF363636);
  static const Color mediumGrey = Color(0xFF595C5C);
  static const Color lightGrey = Color(0xFF9D9C9C);
  static const Color smoke = Color(0xFFF0F0F0);
  static const Color white = Color(0xFFFFFFFF);

  // ── Primary Purple (Pinkish) ──
  static const Color purpleDark1 = Color(0xFF3D0F2F);
  static const Color purpleDark2 = Color(0xFF771D5C);
  static const Color mainPurple = Color(0xFFB23495);
  static const Color purpleLight1 = Color(0xFFC554AB);
  static const Color purpleLight2 = Color(0xFFE39BD1);
  static const Color purpleLight3 = Color(0xFFF6DEF2);
  static const Color purpleLight4 = Color(0xFFFCF2F9);

  // ── Primary Blue (Cyan) ──
  static const Color blueDark1 = Color(0xFF0A3335);
  static const Color blueDark2 = Color(0xFF156669);

  // Was #9D9C9C — the same grey as `lightGrey`, which made every
  // blue→purple gradient render grey→magenta instead of cyan→magenta.
  // #32C6CC is the value the design system and the Figma screens use.
  static const Color mainBlue = Color(0xFF32C6CC);
  static const Color blueLight1 = Color(0xFF5FD3D8);
  static const Color blueLight2 = Color(0xFF87DDF1);
  static const Color blueLight3 = Color(0xFFC3F0F2);
  static const Color blueLight4 = Color(0xFFE5FCFD);

  // ── Success ──
  static const Color successDark2 = Color(0xFF115B43);
  static const Color successDark1 = Color(0xFF1B6E53);
  static const Color successMain = Color(0xFF32C997);
  static const Color successLight1 = Color(0xFF84DFC1);
  static const Color successLight2 = Color(0xFFF1FBF8);

  // ── Warning ──
  static const Color warningDark1 = Color(0xFFE48900);
  static const Color warningMain = Color(0xFFFFB240);
  static const Color warningLight1 = Color(0xFFFFD596);
  static const Color warningLight2 = Color(0xFFFFF8EC);

  // ── Error ──
  static const Color errorDark1 = Color(0xFFC33025);
  static const Color errorMain = Color(0xFFFF5A4F);
  static const Color errorLight1 = Color(0xFFF0B57D);
  static const Color errorLight2 = Color(0xFFFFF1F0);

  // ── Gradients ──

  /// The brand gradient: teal straight across into DSH pink.
  ///
  /// The same two colours and the same 90° as `.gradient-text` in the site's
  /// `globals.css` — `linear-gradient(90deg, #32C6CC, #B23495)`.
  ///
  /// It was `topStart → bottomEnd` for a while (a true 45°, far steeper than
  /// anything on the site), then a 5.17° tilt copied from one of the site's
  /// nine gradients. Both are gone; see the notes on the stops and the
  /// alignment below for why flat and stopped beats tilted and edge-to-edge
  /// on a short run of text.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [mainBlue, mainPurple],
    // Stops, and they are the reason this reads as teal→pink rather than as a
    // wash.
    //
    // Edge to edge, pure #32C6CC exists only at x=0 and pure #B23495 only at
    // x=1 — neither is ever more than a hairline, and everything between is
    // the blend. Across two words that is all you see: a pale blue-grey
    // sliding into a dull mauve. Holding each colour for the first and last
    // 18% gives both ends a run long enough to be recognised, and compresses
    // the transition into the middle where a blend belongs.
    //
    // The site does the same thing by accident: its phrases are long, so even
    // an unstopped ramp spends real distance near each end.
    stops: [0.18, 0.82],
    // A true 90°, matching `linear-gradient(90deg, …)` in globals.css.
    //
    // This was tilted 5.17° to match the site's `95.17deg`. On the site that
    // tilt is spread over a full-width headline; on a two-word run in a box a
    // few hundred pixels wide it costs vertical range and buys nothing — the
    // gradient just starts a little into the ramp, which is exactly the
    // washed-out look it was meant to avoid.
    //
    // Directional, so in Arabic it runs from the right and keeps flowing with
    // the reading direction instead of against it. Order matters as much as
    // angle: teal always comes first. Pink into teal is the brand gradient
    // backwards.
    begin: AlignmentDirectional.centerStart,
    end: AlignmentDirectional.centerEnd,
  );

  /// Below this, a run of text is short and gets the tightest blend.
  static const double _narrowRun = 110;

  /// Above this, the run has room for [primaryGradient] exactly as defined.
  static const double _wideRun = 260;

  /// [primaryGradient] with its blend narrowed to fit the width it must cross.
  ///
  /// WHY THE STOPS MOVE
  ///
  /// The gradient holds teal for the first 18% and pink for the last 18%,
  /// blending across the 64% between. Over "refuses silence." — most of a
  /// line — that reads exactly as intended: two brand colours with a
  /// transition.
  ///
  /// Over a single short word it does not. "number." is about 110 logical
  /// pixels, so 18% is twenty pixels of teal, twenty of pink, and seventy of
  /// the muddy blue-grey between — which is most of what you see, and it is
  /// why that word looked like it had missed the gradient rather than carried
  /// it.
  ///
  /// The fix is not a different gradient. It is the same two colours with the
  /// blend compressed as the box narrows: a short run gets 35% pure teal, 30%
  /// transition, 35% pure pink, so both brand colours are unmistakable and the
  /// ramp still runs the right way. A wide run keeps the original 18/64/18,
  /// and anything between is interpolated — so a headline whose runs differ in
  /// length does not end up with two visibly different treatments in it.
  ///
  /// Lives here rather than in one widget because two widgets paint gradient
  /// text, and the first version of this fix reached only one of them.
  static LinearGradient brandRamp(double width) {
    // 0 at the narrow end, 1 at the wide end.
    final t = ((width - _narrowRun) / (_wideRun - _narrowRun)).clamp(0.0, 1.0);

    // 0.35 → 0.18 as the run widens.
    final inset = 0.35 + (0.18 - 0.35) * t;

    return LinearGradient(
      colors: primaryGradient.colors,
      begin: primaryGradient.begin,
      end: primaryGradient.end,
      stops: [inset, 1 - inset],
    );
  }

  // ── Legacy/Copied MontCamp Aliases ──

  /// The page colour.
  ///
  /// Was `darkBackground` — #1B1B1B — because this alias was copied wholesale
  /// from MontCamp, whose palette starts one step lighter than DSH's. Every
  /// screen built since then set its scaffold to `deepBackground` (#0D0D0D),
  /// which is what the frames draw; the ones still on this alias were Home,
  /// the tab shell, Read, Academy, Profile, Events, Notifications and Splash —
  /// so the app had two page colours, and the difference was visible the
  /// moment you moved between a tab and anything reached from it.
  ///
  /// Repointed rather than replaced at each call site: every remaining use is
  /// either a scaffold background or a scrim over a photograph, and all of
  /// them want the darker value.
  static const Color brandBlack = deepBackground;
  static const Color brandWhite = white;
  static const Color brandGold =
      warningMain; // Mapping to orange/gold from MontCamp

  // ── Semantic Aliases ──
  static const Color primary = mainPurple;
  static const Color secondary = mainBlue;

  static const Color success = successMain;
  static const Color error = errorMain;
  static const Color warning = warningMain;

  // ── Backgrounds & Surfaces ──
  /// The theme's `scaffoldBackgroundColor` — so any screen that does NOT set
  /// its own background gets the page colour rather than the card colour.
  ///
  /// Same correction as [brandBlack] above, and the reason the two had to move
  /// together: a screen with no explicit background fell through to this one,
  /// so fixing only the explicit ones would have left the difference visible
  /// on exactly the screens nobody thought to check.
  static const Color background = deepBackground;
  static const Color backgroundLight = smoke;
  static const Color surface = mediumBackground;
  static const Color surfaceLight = white;

  // ── Text Colors ──
  static const Color textPrimary = white;
  static const Color textSecondary = lightGrey;
  static const Color textMuted = mediumGrey;

  static const Color textPrimaryLight = darkBackground;
  static const Color textSecondaryLight = mediumGrey;
  static const Color textMutedLight = lightGrey;

  // ── Borders ──
  static const Color border = mediumBackground;
  static const Color borderLight = smoke;

  // ── Navigation ──
  static const Color navActive = mainPurple;
  static const Color navInactive = lightGrey;

  // ── Academy ──

  /// The lime that marks a free programme — Figma 2266:1038 / 2266:1118, and
  /// `FREE` in the website's `AcademyListing.tsx`.
  ///
  /// Its own colour rather than [successMain] on purpose. Green means "this
  /// worked"; the Academy frame uses this to mean "this costs nothing", which
  /// is a fact about the programme and not a result of anything the reader
  /// did. Reusing the success green would have made a price look like a
  /// confirmation, and would have tied two unrelated things to one value.
  static const Color academyFree = Color(0xFFBCCB2E);

  /// The grey the Academy frame uses for a placeholder and for the delivery
  /// format beside a chip — #555, between [mediumGrey] and [darkBackground]
  /// and equal to neither.
  static const Color academyMuted = Color(0xFF555555);
}
