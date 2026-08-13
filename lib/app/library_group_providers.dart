part of 'library_providers.dart';

final libraryGroupsProvider =
    AsyncNotifierProvider<LibraryGroupsNotifier, List<LibraryGroup>>(
      LibraryGroupsNotifier.new,
    );

class LibraryGroupsNotifier extends AsyncNotifier<List<LibraryGroup>> {
  late LibraryRepository _repository;
  LibraryGroupKind kind = LibraryGroupKind.album;
  String search = '';
  int totalCount = 0;
  LibraryGroupCursor? _nextCursor;
  bool isLoadingMore = false;
  int _queryGeneration = 0;

  String? get _sourceKey => ref.read(libraryProvider.notifier).activeSourcePath;

  @override
  Future<List<LibraryGroup>> build() async {
    _repository = ref.watch(libraryRepositoryProvider);
    await ref.watch(libraryProvider.future);
    final page = await _queryFirstPage(kind: kind, search: search);
    _applyPage(page);
    return page.items;
  }

  Future<LibraryGroupPage> _queryFirstPage({
    required LibraryGroupKind kind,
    required String search,
  }) => _repository.queryGroups(
    LibraryGroupQuery(kind: kind, sourceKey: _sourceKey, search: search),
  );

  void _applyPage(LibraryGroupPage page) {
    totalCount = page.totalCount;
    _nextCursor = page.nextCursor;
  }

  Future<void> setQuery({LibraryGroupKind? kind, String? search}) async {
    this.kind = kind ?? this.kind;
    this.search = search ?? this.search;
    final generation = ++_queryGeneration;
    isLoadingMore = false;
    state = const AsyncLoading<List<LibraryGroup>>().copyWithPrevious(state);
    try {
      final page = await _queryFirstPage(kind: this.kind, search: this.search);
      if (generation != _queryGeneration) return;
      _applyPage(page);
      state = AsyncData(page.items);
    } catch (error, stackTrace) {
      if (generation == _queryGeneration) {
        state = AsyncError(error, stackTrace);
      }
    }
  }

  Future<void> loadNextPage() async {
    final cursor = _nextCursor;
    if (cursor == null || isLoadingMore) return;
    final generation = _queryGeneration;
    final currentKind = kind;
    final currentSearch = search;
    isLoadingMore = true;
    try {
      final page = await _repository.queryGroups(
        LibraryGroupQuery(
          kind: currentKind,
          sourceKey: _sourceKey,
          search: currentSearch,
          cursor: cursor,
        ),
      );
      if (generation != _queryGeneration) return;
      _nextCursor = page.nextCursor;
      totalCount = page.totalCount;
      state = AsyncData([
        ...state.valueOrNull ?? const <LibraryGroup>[],
        ...page.items,
      ]);
    } finally {
      isLoadingMore = false;
    }
  }
}
