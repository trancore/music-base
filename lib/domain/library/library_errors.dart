class LibraryAccessException implements Exception {
  const LibraryAccessException(this.message);

  final String message;

  @override
  String toString() => message;
}
