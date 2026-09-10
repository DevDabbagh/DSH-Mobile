import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';

void main() {
  testWidgets('Generate PNG', (WidgetTester tester) async {
    final rootKey = GlobalKey();
    
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: rootKey,
          child: Container(
            width: 1000,
            height: 1000, // Make it square for splash icon
            color: Colors.transparent, // Ensure it's transparent
            alignment: Alignment.center,
            child: SvgPicture.file(File('assets/Logo.svg'), width: 800),
          ),
        ),
      ),
    );
    
    await tester.pumpAndSettle();
    
    RenderRepaintBoundary boundary = rootKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();
    
    final file = File('assets/icons/ic_logo_transparent.png');
    await file.writeAsBytes(buffer);
    print('Generated successfully at ${file.absolute.path}');
  });
}
