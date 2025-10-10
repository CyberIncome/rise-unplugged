import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

class FadeScaleSwitcher extends StatelessWidget {
  const FadeScaleSwitcher({
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    super.key,
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return PageTransitionSwitcher(
      duration: duration,
      reverse: false,
      transitionBuilder: (child, animation, secondaryAnimation) {
        return FadeScaleTransition(
          animation: animation,
          child: child,
        );
      },
      child: KeyedSubtree(
        key: ValueKey(child.hashCode),
        child: child,
      ),
    );
  }
}
