import 'package:equatable/equatable.dart';

class BookContent extends Equatable {
  const BookContent({
    required this.bookIdentifier,
    required this.chapterIdentifier,
    required this.content,
  });

  final String bookIdentifier;
  final String chapterIdentifier;
  final String content;

  @override
  List<Object?> get props => <Object>[
        bookIdentifier,
        chapterIdentifier,
        content,
      ];
}
