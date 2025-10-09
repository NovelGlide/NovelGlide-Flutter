class ReaderPageNotInBookException implements Exception {
  ReaderPageNotInBookException({
    this.message = 'This page is not in the book.',
    required this.pageIdentifier,
  });

  String message;
  String? pageIdentifier;

  @override
  String toString() =>
      'ReaderPageNotInBookException: $message ($pageIdentifier)';
}
