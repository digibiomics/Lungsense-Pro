import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lungsense_pro/core/widgets/ls_components.dart';

Widget _host(Widget child, {double width = 360}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SizedBox(width: width, child: child),
    ),
  ),
);

void main() {
  group('LsKeyValueRow', () {
    testWidgets('short values share one right edge, flush with the panel', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const LsPanel(
            children: [
              LsKeyValueRow(label: 'Breathlessness', value: '2 · Moderate'),
              LsKeyValueRow(label: 'Cough', value: '0 · None'),
              LsKeyValueRow(label: 'Activity limitation', value: 'Not rated'),
            ],
          ),
        ),
      );

      final panelRight = tester.getTopRight(find.byType(LsPanel)).dx;
      final rights = [
        for (final v in ['2 · Moderate', '0 · None', 'Not rated'])
          tester.getTopRight(find.text(v)).dx,
      ];
      // Value text boxes all end 16px inside the panel.
      for (final r in rights) {
        expect(r, moreOrLessEquals(panelRight - 16, epsilon: 1.5));
      }
      // Single line: value sits level with its label.
      expect(
        tester.getTopLeft(find.text('0 · None')).dy,
        moreOrLessEquals(tester.getTopLeft(find.text('Cough')).dy, epsilon: 1),
      );
      final text = tester.widget<Text>(find.text('0 · None'));
      expect(text.textAlign, TextAlign.end);
    });

    testWidgets('a value that does not fit drops under the label, left edge', (
      tester,
    ) async {
      const long =
          'Smoker for 20 years, quit in 2019. Mild wheeze on exertion, '
          'no fever this week.';
      await tester.pumpWidget(
        _host(const LsKeyValueRow(label: 'Notes', value: long)),
      );

      final label = tester.getTopLeft(find.text('Notes'));
      final value = tester.getTopLeft(find.text(long));
      expect(value.dx, moreOrLessEquals(label.dx, epsilon: 0.5));
      expect(value.dy, greaterThan(label.dy));
      expect(tester.takeException(), isNull);
    });

    testWidgets('stacked forces the label-above-value layout', (tester) async {
      await tester.pumpWidget(
        _host(const LsKeyValueRow(label: 'Notes', value: 'OK', stacked: true)),
      );
      expect(
        tester.getTopLeft(find.text('OK')).dx,
        moreOrLessEquals(tester.getTopLeft(find.text('Notes')).dx),
      );
      expect(
        tester.getTopLeft(find.text('OK')).dy,
        greaterThan(tester.getTopLeft(find.text('Notes')).dy),
      );
    });

    testWidgets('no overflow at a narrow width with a large text scale', (
      tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: _host(
            const LsKeyValueRow(
              label: 'Session ID',
              value: '3f9c1a2e-7b44-4d1e-9a51-0c2f8e6d7b10',
            ),
            width: 280,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('LsFactGrid', () {
    testWidgets('lays facts out in two equal columns, wide entries below', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const LsFactGrid(
            facts: [
              ('Hospital ref.', 'HSP-22904'),
              ('Registered', '21 Oct 2026'),
              ('Age', '54 years'),
              ('Sex', 'Male'),
              ('Research consent', 'Given'),
            ],
            wide: [('Notes', 'Asthma since childhood.')],
          ),
          // The test font is wide; keep every label on one line.
          width: 600,
        ),
      );

      double left(String s) => tester.getTopLeft(find.text(s)).dx;
      double top(String s) => tester.getTopLeft(find.text(s)).dy;

      expect(left('HSP-22904'), left('54 years'));
      expect(left('HSP-22904'), left('Given'));
      expect(left('21 Oct 2026'), left('Male'));
      expect(left('21 Oct 2026'), greaterThan(left('HSP-22904')));
      expect(top('HSP-22904'), top('21 Oct 2026'));
      expect(top('Hospital ref.'), lessThan(top('HSP-22904')));
      expect(left('Asthma since childhood.'), left('HSP-22904'));
      expect(top('Asthma since childhood.'), greaterThan(top('Given')));
    });
  });
}
