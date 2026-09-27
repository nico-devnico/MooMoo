import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moomoo/core/theme/app_icons.dart';
import 'package:moomoo/presentation/widgets/app_nav_bar.dart';

void main() {
  testWidgets('centred nav bar pins actions to the right edge', (tester) async {
    tester.view.physicalSize = const Size(1400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              AppNavBar(
                centerDestinations: true,
                brand: const Text('Brand'),
                selectedIndex: 0,
                onDestinationSelected: (_) {},
                destinations: const [
                  NavBarDestination(
                    icon: AppIcons.home,
                    selectedIcon: AppIcons.home,
                    label: 'A',
                  ),
                  NavBarDestination(
                    icon: AppIcons.home,
                    selectedIcon: AppIcons.home,
                    label: 'B',
                  ),
                ],
                actions: const [
                  SizedBox(key: Key('avatar'), width: 36, height: 36),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    final bar = tester.getRect(find.byType(AppNavBar));
    expect(bar.width, 1400);

    final avatar = tester.getRect(find.byKey(const Key('avatar')));
    expect(bar.right - avatar.right, lessThan(64));

    final linkA = tester.getRect(find.text('A'));
    final linkB = tester.getRect(find.text('B'));
    final linksCenter = (linkA.left + linkB.right) / 2;
    expect((linksCenter - bar.center.dx).abs(), lessThan(24));
  });
}
