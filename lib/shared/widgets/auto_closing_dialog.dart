import 'dart:async';

import 'package:flutter/material.dart';

Future<T?> showAutoClosingDialog<T>({
  required BuildContext context,
  required Duration duration,
  required WidgetBuilder builder,
  VoidCallback? onAutoClose,
  bool barrierDismissible = false,
}) {
  Timer? timer;
  var isOpen = true;
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) {
      timer ??= Timer(duration, () {
        if (!isOpen || !dialogContext.mounted) return;
        onAutoClose?.call();
        Navigator.pop(dialogContext);
      });
      return builder(dialogContext);
    },
  ).whenComplete(() {
    isOpen = false;
    timer?.cancel();
  });
}
