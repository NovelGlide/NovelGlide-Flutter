import 'package:flutter/material.dart';

abstract class AppAnimatedSwitcher extends StatelessWidget {
  const AppAnimatedSwitcher({
    super.key,
    this.duration,
    this.child,
  });

  final Duration? duration;
  final Widget? child;
}
