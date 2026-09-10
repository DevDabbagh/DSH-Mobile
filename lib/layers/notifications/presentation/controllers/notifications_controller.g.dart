// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notifications_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$unreadCountHash() => r'f662c39e42d1087c67740f05945264fe197abd22';

/// The badge number.
///
/// Its own provider rather than `inbox.length` so the badge does not require
/// the inbox to have been loaded — it is read on screens that never open it.
///
/// Copied from [unreadCount].
@ProviderFor(unreadCount)
final unreadCountProvider = FutureProvider<int>.internal(
  unreadCount,
  name: r'unreadCountProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$unreadCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UnreadCountRef = FutureProviderRef<int>;
String _$notificationsControllerHash() =>
    r'a67458aed0b260ed3627959e79ff8e8e0f14cdc3';

/// The inbox.
///
/// keepAlive, like the other content lists: returning to the screen should
/// show what was already loaded, not a spinner. `refresh()` is the explicit
/// way to go and look again — pull-to-refresh, and after a push arrives.
///
/// Copied from [NotificationsController].
@ProviderFor(NotificationsController)
final notificationsControllerProvider = AsyncNotifierProvider<
    NotificationsController, List<AppNotification>>.internal(
  NotificationsController.new,
  name: r'notificationsControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationsControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$NotificationsController = AsyncNotifier<List<AppNotification>>;
String _$pushRegistrationHash() => r'6ef81616e9455c36ec50a896f558dc5f2b08e412';

/// Keeps the device row in step with the app.
///
/// Watched once, high in the widget tree. Three things on `push_devices` are
/// what the dashboard filters on — who owns the device, what language it
/// reads, and when it was last seen — and all three change while the app is
/// running. Registering only at launch would mean someone who signs in, or
/// switches to Arabic, keeps receiving as whoever and whatever they were
/// when the app started.
///
/// Copied from [PushRegistration].
@ProviderFor(PushRegistration)
final pushRegistrationProvider =
    AsyncNotifierProvider<PushRegistration, void>.internal(
  PushRegistration.new,
  name: r'pushRegistrationProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pushRegistrationHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PushRegistration = AsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
