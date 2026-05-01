import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forgetrack/shared/widgets/drag_reveal_pager.dart';

void main() {
  group('FtDragRevealPager', () {
    testWidgets('commits to the next item after a long left drag',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 200,
                child: _PagerHarness(initialItem: 1),
              ),
            ),
          ),
        ),
      );

      expect(find.text('item 1'), findsOneWidget);

      await tester.drag(
          find.byKey(const ValueKey('pager-surface')), const Offset(-180, 0));
      await tester.pumpAndSettle();

      expect(find.text('item 2'), findsOneWidget);
    });

    testWidgets('snaps back after a short drag', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 200,
                child: _PagerHarness(initialItem: 1),
              ),
            ),
          ),
        ),
      );

      await tester.drag(
          find.byKey(const ValueKey('pager-surface')), const Offset(-40, 0));
      await tester.pumpAndSettle();

      expect(find.text('item 1'), findsOneWidget);
    });
  });

  group('FtEdgePageHandoff', () {
    testWidgets('commits to the target page when enabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(
              child: _EdgeHandoffHarness(enabled: true),
            ),
          ),
        ),
      );

      expect(find.text('center'), findsOneWidget);

      await tester.drag(
          find.byKey(const ValueKey('edge-surface')), const Offset(-220, 0));
      await tester.pumpAndSettle();

      expect(find.text('target'), findsOneWidget);
    });

    testWidgets('stays on the current page when disabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(
              child: _EdgeHandoffHarness(enabled: false),
            ),
          ),
        ),
      );

      await tester.drag(
          find.byKey(const ValueKey('edge-surface')), const Offset(-220, 0));
      await tester.pumpAndSettle();

      expect(find.text('center'), findsOneWidget);
      expect(find.text('target'), findsNothing);
    });
  });
}

class _PagerHarness extends StatefulWidget {
  const _PagerHarness({required this.initialItem});

  final int initialItem;

  @override
  State<_PagerHarness> createState() => _PagerHarnessState();
}

class _PagerHarnessState extends State<_PagerHarness> {
  late int _currentItem;

  @override
  void initState() {
    super.initState();
    _currentItem = widget.initialItem;
  }

  @override
  Widget build(BuildContext context) {
    return DragRevealPager<int>(
      item: _currentItem,
      hasPrevious: (item) => item > 0,
      hasNext: (item) => item < 2,
      previousOf: (item) => item - 1,
      nextOf: (item) => item + 1,
      onCommit: (item) => setState(() => _currentItem = item),
      builder: (context, item) => Container(
        key: const ValueKey('pager-surface'),
        color: Colors.black,
        alignment: Alignment.center,
        child: Text(
          'item $item',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class _EdgeHandoffHarness extends StatefulWidget {
  const _EdgeHandoffHarness({required this.enabled});

  final bool enabled;

  @override
  State<_EdgeHandoffHarness> createState() => _EdgeHandoffHarnessState();
}

class _EdgeHandoffHarnessState extends State<_EdgeHandoffHarness> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: 1);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _controller,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        const Center(child: Text('start')),
        EdgePageHandoff(
          controller: _controller,
          currentPage: 1,
          targetPage: 2,
          isEnabled: () => widget.enabled,
          child: Container(
            key: const ValueKey('edge-surface'),
            color: Colors.black,
            alignment: Alignment.center,
            child: const Text(
              'center',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        const Center(child: Text('target')),
      ],
    );
  }
}
