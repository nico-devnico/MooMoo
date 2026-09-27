import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moomoo/core/layout/responsive.dart';
import 'package:moomoo/presentation/widgets/app_button.dart';

/// Pumps [child] at a fixed logical window size so breakpoint-dependent
/// widgets can be exercised deterministically.
Future<void> pumpAtWidth(
  WidgetTester tester,
  Widget child, {
  required double width,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(width, 900);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
}

void main() {
  group('Breakpoints', () {
    testWidgets('classifies mobile, tablet and desktop widths', (tester) async {
      final seen = <double, FormFactor>{};

      for (final width in <double>[390, 800, 1440]) {
        await pumpAtWidth(
          tester,
          Builder(
            builder: (context) {
              seen[width] = context.formFactor;
              return const SizedBox.shrink();
            },
          ),
          width: width,
        );
      }

      expect(seen[390], FormFactor.mobile);
      expect(seen[800], FormFactor.tablet);
      expect(seen[1440], FormFactor.desktop);
    });
  });

  group('PageContainer', () {
    testWidgets('caps content width on desktop', (tester) async {
      await pumpAtWidth(
        tester,
        const PageContainer(
          width: ContentWidth.form,
          child: SizedBox(key: Key('content'), height: 40),
        ),
        width: 1440,
      );

      final contentWidth = tester.getSize(find.byKey(const Key('content'))).width;
      expect(contentWidth, lessThanOrEqualTo(ContentWidth.form.maxWidth));
    });

    testWidgets('fills the available width on mobile', (tester) async {
      await pumpAtWidth(
        tester,
        const PageContainer(
          width: ContentWidth.form,
          child: SizedBox(key: Key('content'), height: 40),
        ),
        width: 390,
      );

      final contentWidth = tester.getSize(find.byKey(const Key('content'))).width;
      expect(contentWidth, lessThan(390));
      expect(contentWidth, greaterThan(300));
    });
  });

  group('AppButton', () {
    testWidgets('stays intrinsic on desktop and stretches on mobile',
        (tester) async {
      await pumpAtWidth(
        tester,
        const Align(
          alignment: Alignment.topLeft,
          child: AppButton(key: Key('btn'), label: 'Valider'),
        ),
        width: 1440,
      );
      final desktopWidth = tester.getSize(find.byKey(const Key('btn'))).width;
      expect(desktopWidth, lessThanOrEqualTo(AppButton.desktopMaxWidth));

      await pumpAtWidth(
        tester,
        const Align(
          alignment: Alignment.topLeft,
          child: AppButton(key: Key('btn'), label: 'Valider'),
        ),
        width: 390,
      );
      final mobileWidth = tester.getSize(find.byKey(const Key('btn'))).width;
      expect(mobileWidth, 390);
    });

    testWidgets('meets the minimum touch target height', (tester) async {
      await pumpAtWidth(
        tester,
        const AppButton(key: Key('btn'), label: 'Valider'),
        width: 390,
      );

      expect(
        tester.getSize(find.byKey(const Key('btn'))).height,
        greaterThanOrEqualTo(48),
      );
    });
  });
}
