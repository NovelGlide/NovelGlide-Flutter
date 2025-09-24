import 'package:flutter/material.dart';

import '../widgets/nav/navigation_bar.dart';
import '../widgets/reader_app_bar.dart';
import '../widgets/reader_scaffold_body.dart';

class ReaderCompactView extends StatelessWidget {
  const ReaderCompactView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: ReaderAppBar(),
      body: SafeArea(
        child: ReaderScaffoldBody(),
      ),
      bottomNavigationBar: SafeArea(child: ReaderNavigationBar()),
    );
  }
}
