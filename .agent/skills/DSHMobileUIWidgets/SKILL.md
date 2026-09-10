---
name: DSH Mobile UI & Widgets
description: Strict guidelines for building screens, styling widgets natively, and handling English/Arabic/Portuguese translations and RTL in the Don't Skip Humanity (DSH) Mobile application.
---

# DSH Mobile UI & Widgets Design

When asked to design a screen, use UI widgets, or style a page, you **MUST** strictly adhere to these standards.

## 1. Theming and Colors

**NEVER** hardcode HEX colors anywhere. **ALWAYS** use `AppColors`.
- Use `.withValues(alpha: 0.1)` — `.withOpacity()` is deprecated.
- Example: `Container(color: AppColors.brandBlack)`

## 2. Spacing and Dimensions

**NEVER** use raw numeric literals for spacing (e.g. `EdgeInsets.all(16)`). Use `AppDimensions`.

**ALWAYS** use `EdgeInsetsDirectional` instead of `EdgeInsets`, and `start`/`end` instead of `left`/`right`. The app ships in Arabic; `left` padding silently breaks RTL layouts.

Same rule for `Alignment` → prefer `AlignmentDirectional`, and `BorderRadius.only` → `BorderRadiusDirectional.only`.

## 3. Responsive Sizing with ScreenUtil

All screens and custom widgets **MUST** apply `.h`, `.w`, `.r`, `.sp` to numeric sizes.
Combine with tokens: `AppDimensions.pagePadding.w`.
Design reference: 428×926.

## 4. Localization — THREE languages

The app supports **English, Arabic, and Portuguese**. There are three ARB files:
`assets/translations/app_en.arb` · `app_ar.arb` · `app_pt.arb`

**CRITICAL RULE FOR DESIGNS FROM IMAGES:** When building a UI from an image or screenshot, **NEVER** hardcode the text you see. Extract every string, add it to **all three** ARB files with a sensible key, and use `AppLocalizations.of(context)!.key`.

- **CRITICAL**: after editing any `.arb`, run `flutter gen-l10n`.
- A key added to only one file is a bug — the other languages fall back to English silently.

See `examples/example_localized_screen.dart`.

### Two distinct kinds of text — do not confuse them

| Kind | Source | Example |
|---|---|---|
| **Interface strings** | ARB files | "Sign In", "Retry", tab labels |
| **Editorial content** | Supabase JSONB, resolved by `pickLang()` | film titles, article bodies, onboarding copy |

**NEVER** put editorial content in ARB files, and **NEVER** fetch interface labels from a content table.

### RTL checklist for every new screen
- Directional padding/margins/alignment (see §2)
- Icons that imply direction (back/forward arrows) flip — use `Icons.arrow_back` (auto-flips) or check `Directionality.of(context)`
- Test in Arabic before marking a screen done

## 5. Loading, Empty and Error States

Every screen that fetches data needs all three:

- **Loading** → a `Shimmer` skeleton mirroring the real layout, in its own `presentation/widgets/<feature>_shimmer.dart`. **NEVER** a bare `CircularProgressIndicator`.
- **Empty** → `EmptyStateWidget`
- **Error** → `ErrorRetryWidget` with a retry that calls `ref.invalidate(...)`. **NEVER** a raw `Text(error.toString())`.

For mutations, use `LoadingOverlay.show(context)` driven by `ref.listen` (see the Riverpod skill).

See `examples/example_shimmer.dart`.

## 6. Images

Remote images **MUST** use `CachedNetworkImage` with a shimmer `placeholder` and an `errorWidget`.

For lists and animated rows, pass `memCacheWidth` so full-resolution bitmaps do not accumulate in memory. Wrap continuously animating rows in `RepaintBoundary`.

**NEVER** ship placeholder URLs (`unsplash.com`, `picsum.photos`, `pravatar.cc`) in a finished screen — every image comes from Supabase storage or `assets/`.

## 7. File Size

Page files **MUST** stay under ~400 lines. Extract sections into `presentation/widgets/`. A 1000-line page is not reviewable and cannot be reused.

## 8. Shared Widget Catalog

Always reuse what exists before writing a new widget:

`CustomButton` · `CustomTextField` · `CustomCheckbox` · `SocialButton` · `GradientText` · `Loader` · `LoadingOverlay` · `ErrorRetryWidget` · `EmptyStateWidget` · `SectionHeader`

See `examples/example_custom_button.dart` for dynamic styling (grey vs primaryGradient).

## 9. Highlighted Text Pattern

Titles where the **last segment** is gradient-coloured come from two separate fields (`title` + `titleHighlight`) — never from markup inside one string. Render with `RichText` + a `WidgetSpan` wrapping `GradientText`:

```dart
RichText(
  text: TextSpan(
    style: textTheme.displayLarge,
    children: [
      TextSpan(text: '${slide.title} '),
      WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: GradientText(
          slide.titleHighlight,
          gradient: AppColors.primaryGradient,
          style: textTheme.displayLarge,
        ),
      ),
    ],
  ),
)
```
