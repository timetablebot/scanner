import 'dart:math';

import 'package:cafeteria_scanner/data/meal_scanner.dart';
import 'package:flutter/material.dart';

class TextBoxPainter extends CustomPainter {
  TextBoxPainter(this.scanner, this.blockId);

  final MealScanner scanner;
  final int blockId;

  @override
  void paint(Canvas canvas, Size size) {
    // https://github.com/flutter/plugins/blob/master/packages/
    // firebase_ml_vision/example/lib/detector_painters.dart#L124

    final Paint paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.green.withOpacity(0.3);
      //..strokeWidth = 3.0;

    final block = scanner.getIdentifyBlock(blockId);
    canvas.drawRRect(scaleRect(size, block.box), paint);
  }

  RRect scaleRect(Size size, Rectangle<int> box) {
    final double scaleX = size.width / scanner.imageSize.width;
    final double scaleY = size.height / scanner.imageSize.height;

    return RRect.fromLTRBR(
      box.left * scaleX,
      box.top * scaleY,
      box.right * scaleY,
      box.bottom * scaleY,
      Radius.circular(8)
    );
  }

  @override
  bool shouldRepaint(TextBoxPainter oldDelegate) {
    return scanner.image != oldDelegate.scanner.image ||
        blockId != oldDelegate.blockId;
  }
}
