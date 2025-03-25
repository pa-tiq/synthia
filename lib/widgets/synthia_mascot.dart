import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SynthiaMascot extends StatelessWidget {
  final double width;
  final double height;

  const SynthiaMascot({Key? key, this.width = 200, this.height = 200})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/svgs/synthia.svg',
      width: width,
      height: height,
      semanticsLabel: 'Synthia Mascot',
      placeholderBuilder: (context) => const CircularProgressIndicator(),
      // This errorBuilder will show an error message if loading fails.
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Text(
            'Error loading mascot',
            style: TextStyle(color: Colors.red),
          ),
        );
      },
    );
  }
}
