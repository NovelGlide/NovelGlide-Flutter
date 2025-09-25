import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../main.dart';
import 'cubit/reader_core_html_cubit.dart';

class ReaderCoreHtml extends StatelessWidget {
  const ReaderCoreHtml({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReaderCoreHtmlCubit>(
      create: (_) => sl<ReaderCoreHtmlCubit>(),
      child: const Center(
        child: Text('HTML core'),
      ),
    );
  }
}
