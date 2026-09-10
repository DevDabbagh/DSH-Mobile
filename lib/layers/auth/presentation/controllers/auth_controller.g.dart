// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentUserHash() => r'7477df35fa854f5020c420a24a5f7898ddb98ef9';

/// Who is signed in, or null.
///
/// Named CurrentUser rather than AuthState because `supabase_flutter` exports
/// a type by that name, and two of them in one file is a trap for whoever
/// reads it next.
///
/// keepAlive because the whole app reads it — the router guard, the profile
/// screen, anything gated behind an account. It restores the persisted
/// session on first read, then follows Supabase's auth stream.
///
/// Copied from [CurrentUser].
@ProviderFor(CurrentUser)
final currentUserProvider =
    AsyncNotifierProvider<CurrentUser, AppUser?>.internal(
  CurrentUser.new,
  name: r'currentUserProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$currentUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CurrentUser = AsyncNotifier<AppUser?>;
String _$pendingVerificationStateHash() =>
    r'75c593c7196044da1d02e0a216020a0538114a10';

/// See also [PendingVerificationState].
@ProviderFor(PendingVerificationState)
final pendingVerificationStateProvider =
    NotifierProvider<PendingVerificationState, PendingVerification?>.internal(
  PendingVerificationState.new,
  name: r'pendingVerificationStateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pendingVerificationStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PendingVerificationState = Notifier<PendingVerification?>;
String _$authControllerHash() => r'836f0be27cb70499fcb011445d56c597e2fc3a3f';

/// Drives the auth screens.
///
/// Method names and signatures match what the screens already call, so the
/// UI built to the design needed no changes to get real authentication.
///
/// Copied from [AuthController].
@ProviderFor(AuthController)
final authControllerProvider =
    AutoDisposeAsyncNotifierProvider<AuthController, void>.internal(
  AuthController.new,
  name: r'authControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AuthController = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
