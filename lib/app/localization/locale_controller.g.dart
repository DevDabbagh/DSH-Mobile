// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locale_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$isRtlHash() => r'c9830264d7196b32250d8dd1a84c6a59ea769401';

/// Whether the current language is written right-to-left.
///
/// Flutter handles direction from the Locale on its own; this is for the few
/// places that need to know explicitly — mirroring an icon, say.
///
/// Copied from [isRtl].
@ProviderFor(isRtl)
final isRtlProvider = AutoDisposeProvider<bool>.internal(
  isRtl,
  name: r'isRtlProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$isRtlHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsRtlRef = AutoDisposeProviderRef<bool>;
String _$localeControllerHash() => r'3ca191d1f698ce64ad2d5f3eaa6f272952509580';

/// The language the app is displayed in.
///
/// Two things read this: `MaterialApp.router` for interface strings, and
/// every content repository, which passes the code to `pickLang` so Supabase
/// text comes back in the same language. Because it is a provider, changing
/// it rebuilds the UI and refetches content together — the two can't drift
/// into showing an Arabic interface over English copy.
///
/// keepAlive so the choice survives navigation.
///
/// Copied from [LocaleController].
@ProviderFor(LocaleController)
final localeControllerProvider =
    NotifierProvider<LocaleController, Locale>.internal(
  LocaleController.new,
  name: r'localeControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$localeControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$LocaleController = Notifier<Locale>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
