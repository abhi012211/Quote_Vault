import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ShareService {
  static Future<void> shareText(String text) async {
    await Share.share(text);
  }

  // Basic implementation for image sharing - requires RepaintBoundary in UI
  static Future<void> shareWidgetImage(GlobalKey key) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/quote_share.png';
      final file = File(path);
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles([
        XFile(path),
      ], text: 'Check out this quote from QuoteVault!');
    } catch (e) {
      debugPrint('Error sharing image: $e');
    }
  }
}
