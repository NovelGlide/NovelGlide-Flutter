import 'package:flutter/material.dart';

import 'app_animated_switcher.dart';

class SimpleFadeSwitcher extends AppAnimatedSwitcher {
  const SimpleFadeSwitcher({
    super.key,
    super.duration,
    super.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration ?? const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) =>
          FadeTransition(opacity: animation, child: child),
      child: child,
    );
  }
}
