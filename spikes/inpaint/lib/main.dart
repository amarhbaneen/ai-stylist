import 'package:flutter/widgets.dart';

/// The spike has no UI: run integration_test/inpaint_benchmark_test.dart.
void main() => runApp(
  const Center(
    child: Text(
      'Inpainting spike: run the integration test.',
      textDirection: TextDirection.ltr,
    ),
  ),
);
