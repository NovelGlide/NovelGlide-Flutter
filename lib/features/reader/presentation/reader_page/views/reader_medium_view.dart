import 'package:flutter/material.dart';

import '../widgets/nav/navigation_rail.dart';
import '../widgets/reader_app_bar.dart';
import '../widgets/reader_scaffold_body.dart';

class ReaderMediumView extends StatelessWidget {
  const ReaderMediumView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: ReaderAppBar(),
      body: SafeArea(
        child: Row(
          children: <Widget>[
            ReaderNavigationRail(),
            Expanded(child: ReaderScaffoldBody()),
          ],
        ),
      ),
    );
  }
}
