import 'package:flutter/material.dart';

class Badged extends StatelessWidget {
  final String? badge;
  final Widget child;

  const Badged({Key? key, required this.child, this.badge}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (badge == null) {
      return child;
    }
    return Stack(
      children: [
        child,
        Positioned(
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(6),
            ),
            constraints: const BoxConstraints(
              minWidth: 12,
              minHeight: 12,
            ),
            child: Text(
              badge!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
