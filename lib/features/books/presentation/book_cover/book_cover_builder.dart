import 'package:flutter/material.dart';

import '../../../../main.dart';
import '../../../shared_components/animated_switchers/simple_fade_switcher.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/book_cover.dart';
import '../../domain/use_cases/book_get_cover_use_case.dart';
import 'book_cover_widget.dart';

class BookCoverBuilder extends StatelessWidget {
  const BookCoverBuilder({
    super.key,
    required this.bookData,
    this.builder,
    this.placeholder,
  });

  final Book bookData;
  final Widget? Function(BuildContext context, BookCover coverData)? builder;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BookCover>(
      future: sl<BookGetCoverUseCase>()(bookData.coverIdentifier),
      builder: (BuildContext context, AsyncSnapshot<BookCover> snapshot) {
        Widget? child = placeholder;

        if (snapshot.hasData) {
          child = builder?.call(context, snapshot.data!) ??
              BookCoverWidget(
                coverData: snapshot.data!,
                fit: BoxFit.contain,
              );
        }

        return SimpleFadeSwitcher(child: child);
      },
    );
  }
}
