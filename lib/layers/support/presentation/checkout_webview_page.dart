import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/config/site_config.dart';

/// How the donor left checkout.
enum CheckoutStatus {
  /// Stripe redirected to the success URL. The payment went through — but the
  /// donation is only confirmed once the session has been verified with the
  /// server, which the caller does next.
  success,

  /// Stripe redirected to the cancel URL — the donor pressed Stripe's own
  /// back link.
  cancelled,

  /// The donor closed the screen themselves. Not the same as cancelled: the
  /// payment may in fact have completed a moment before, so the caller still
  /// checks rather than assuming nothing happened.
  dismissed,
}

class CheckoutOutcome {
  final CheckoutStatus status;

  /// `cs_test_…` / `cs_live_…`, present on success.
  final String? sessionId;

  const CheckoutOutcome(this.status, {this.sessionId});
}

/// Stripe Checkout, inside the app.
///
/// WHY IN-APP AND NOT THE SYSTEM BROWSER
///
/// A donor sent out to a browser has to find their way back, and most do not
/// — they close the tab and the app never learns the gift was made, so no
/// thank-you is ever shown. Keeping the payment in a view we own means the
/// return is automatic: the redirect Stripe performs at the end is a
/// navigation this screen can see, so the moment it happens the view closes
/// and the app knows the session id.
///
/// WHAT THAT COSTS, AND WHAT IS DONE ABOUT IT
///
/// An embedded view has no address bar, and a donor about to type a card
/// number has a right to know whose page they are on. So this screen draws
/// one: the live host of the current page, with a lock, updated on every
/// navigation. It is not decoration — during payment it reads
/// `checkout.stripe.com`, which is the assurance the browser would otherwise
/// have given.
///
/// Nothing sensitive passes through Dart. The card is typed into Stripe's own
/// page inside the view; the app only ever sees the URLs.
class CheckoutWebViewPage extends StatefulWidget {
  final String checkoutUrl;

  const CheckoutWebViewPage({super.key, required this.checkoutUrl});

  @override
  State<CheckoutWebViewPage> createState() => _CheckoutWebViewPageState();
}

class _CheckoutWebViewPageState extends State<CheckoutWebViewPage> {
  late final WebViewController _controller;

  String _host = '';
  bool _loading = true;

  /// Set as soon as a return URL is seen, so the pop that follows carries the
  /// real outcome and the `onPopInvoked` fallback does not overwrite it.
  CheckoutOutcome? _outcome;

  @override
  void initState() {
    super.initState();

    _host = Uri.tryParse(widget.checkoutUrl)?.host ?? '';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.deepBackground)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final outcome = _readReturn(request.url);
            if (outcome == null) return NavigationDecision.navigate;

            // The return page never needs to render — we have what we need
            // from its URL, and letting it load would flash the website
            // inside the app.
            _finish(outcome);
            return NavigationDecision.prevent;
          },
          onPageStarted: (url) {
            final host = Uri.tryParse(url)?.host ?? '';
            if (mounted)
              setState(() {
                _host = host;
                _loading = true;
              });
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onHttpError: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  /// Recognises the URLs the checkout route set as `success_url` /
  /// `cancel_url`: `{site}/support?status=success&session_id=cs_…`.
  ///
  /// Matched on host AND path, not on the query alone — a page inside Stripe's
  /// own flow could carry a `status` parameter of its own, and mistaking one
  /// for the end of checkout would close the view mid-payment.
  CheckoutOutcome? _readReturn(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    final siteHost = Uri.tryParse(SiteConfig.baseUrl)?.host;
    if (siteHost == null || uri.host != siteHost) return null;
    if (!uri.path.startsWith('/support')) return null;

    switch (uri.queryParameters['status']) {
      case 'success':
        return CheckoutOutcome(
          CheckoutStatus.success,
          sessionId: uri.queryParameters['session_id'],
        );
      case 'cancelled':
        return const CheckoutOutcome(CheckoutStatus.cancelled);
      default:
        return null;
    }
  }

  void _finish(CheckoutOutcome outcome) {
    if (!mounted || _outcome != null) return;
    _outcome = outcome;
    Navigator.of(context).pop(outcome);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      // Closing by gesture or by the X returns `dismissed` rather than
      // nothing, so the caller can still check whether a payment landed.
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && result == null) {
          _outcome ??= const CheckoutOutcome(CheckoutStatus.dismissed);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.deepBackground,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(52.h),
          child: SafeArea(
            child: Container(
              height: 52.h,
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              decoration: const BoxDecoration(
                color: AppColors.cardSurface,
                border: Border(
                  bottom: BorderSide(color: AppColors.mediumBackground),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.smoke, size: 22.w),
                    onPressed: () => _finish(
                      const CheckoutOutcome(CheckoutStatus.dismissed),
                    ),
                  ),
                  Icon(Icons.lock_outline,
                      size: 13.w, color: AppColors.successMain),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      _host,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.lightGrey,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                  if (_loading)
                    SizedBox(
                      width: 14.w,
                      height: 14.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 1.6,
                        color: AppColors.mediumGrey,
                      ),
                    ),
                  SizedBox(width: 8.w),
                ],
              ),
            ),
          ),
        ),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}
