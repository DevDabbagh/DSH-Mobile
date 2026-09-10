import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/layers/about/presentation/widgets/about_shortcuts.dart';
import 'package:dsh_mobile/layers/pages/presentation/controllers/page_sections_controller.dart';
import 'package:dsh_mobile/layers/pages/presentation/widgets/page_section_blocks.dart';

/// About — Figma `2046:9060`.
///
/// The copy is NOT in this file. It comes from `page_sections` where page =
/// 'about', the same rows the website renders and the dashboard's Pages editor
/// writes. Carolina changes a paragraph once and both surfaces follow; before
/// this, the app carried its own hardcoded copy and the two drifted.
///
/// Sections arrive ordered and already filtered to the enabled ones, so this
/// screen only decides how each `kind` looks — never what is on the page or in
/// what order.
class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = ref.watch(pageSectionsListProvider('about'));

    return Scaffold(
      backgroundColor: AppColors.deepBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.white, size: 24.w),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'About',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: sections.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.mediumGrey),
        ),
        error: (_, __) => _Retry(
          onRetry: () =>
              ref.read(pageSectionsListProvider('about').notifier).refresh(),
        ),
        data: (list) {
          // "What we do" is drawn as the icon row, not as three stacked text
          // blocks. It is pulled OUT of the normal rendering rather than
          // added alongside it: rendering both put the same three items on
          // the page twice, once as icons and once as prose, which is what
          // the first version of this did.
          //
          // Matched by kind rather than by its label, because the label is
          // editor-written and translated — comparing against the English
          // string would stop matching the moment someone rephrased it, and
          // would never have matched in Portuguese or Arabic at all.
          final shortcutIndex =
              list.indexWhere((s) => s.kind == 'numbered_list');
          final shortcuts = shortcutIndex == -1 ? null : list[shortcutIndex];

          // Every kind rendered nothing — either the page has no sections yet
          // or they are all kinds this build has no widget for. Say so rather
          // than showing a blank scroll view.
          final blocks = [
            for (var i = 0; i < list.length; i++)
              if (i != shortcutIndex) buildPageSection(list[i]),
          ].whereType<Widget>().toList(growable: false);

          if (blocks.isEmpty && shortcuts == null) return const _Empty();

          return RefreshIndicator(
            color: AppColors.mainPurple,
            backgroundColor: AppColors.cardSurface,
            onRefresh: () =>
                ref.read(pageSectionsListProvider('about').notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(bottom: 32.h),
              children: [
                // After the first section — usually the hero — so the page
                // still opens with what DSH is, and the row answers the
                // question that follows it. Not at the very bottom: someone
                // reading About is deciding where to go next, and by then the
                // decision has been made without them.
                if (blocks.isNotEmpty) blocks.first,
                if (shortcuts != null) AboutShortcutRow(section: shortcuts),
                if (blocks.length > 1) ...blocks.sublist(1),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Retry extends StatelessWidget {
  final VoidCallback onRetry;
  const _Retry({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Could not load this page.',
              style: TextStyle(color: AppColors.lightGrey, fontSize: 14.sp),
            ),
            SizedBox(height: 12.h),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Try again',
                style: TextStyle(color: AppColors.mainPurple, fontSize: 14.sp),
              ),
            ),
          ],
        ),
      );
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.w),
          child: Text(
            'Nothing here yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mediumGrey, fontSize: 14.sp),
          ),
        ),
      );
}
