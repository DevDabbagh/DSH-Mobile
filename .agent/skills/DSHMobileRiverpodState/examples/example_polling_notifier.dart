import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'example_polling_notifier.g.dart';

@riverpod
class PollingNotifier extends _$PollingNotifier {
  Timer? _timer;

  @override
  FutureOr<String?> build() async {
    // ✅ ALWAYS cancel on dispose to prevent memory leaks
    ref.onDispose(() => _timer?.cancel());

    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      refreshData();
    });

    return _fetchData();
  }

  Future<String?> _fetchData() async {
    await Future.delayed(const Duration(seconds: 1));
    return "Data fetched at ${DateTime.now()}";
  }

  Future<void> refreshData() async {
    state = const AsyncLoading<String?>().copyWithPrevious(state);
    try {
      final result = await _fetchData();
      state = AsyncData(result);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }
}
