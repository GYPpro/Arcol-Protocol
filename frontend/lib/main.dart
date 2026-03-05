import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  developer.log('[MAIN] Starting app...', name: 'main');
  runApp(
    const ProviderScope(
      child: ArcolProtocolApp(),
    ),
  );
}
