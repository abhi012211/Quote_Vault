// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quote_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(quoteRepository)
final quoteRepositoryProvider = QuoteRepositoryProvider._();

final class QuoteRepositoryProvider
    extends
        $FunctionalProvider<QuoteRepository, QuoteRepository, QuoteRepository>
    with $Provider<QuoteRepository> {
  QuoteRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quoteRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quoteRepositoryHash();

  @$internal
  @override
  $ProviderElement<QuoteRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  QuoteRepository create(Ref ref) {
    return quoteRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QuoteRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QuoteRepository>(value),
    );
  }
}

String _$quoteRepositoryHash() => r'105a411373e08fed92d0cd581d5ec7c4f1a58ba3';
