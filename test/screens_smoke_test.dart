import 'package:adapt_coach/data/community.dart';
import 'package:adapt_coach/data/repository.dart';
import 'package:adapt_coach/main.dart';
import 'package:adapt_coach/state/app_state.dart';
import 'package:adapt_coach/state/community_state.dart';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Every tab and the main screens render without layout errors or
/// exceptions on a small phone, a big one, and with large text.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 9, 29, 12);

  // The app's own font, so text is measured as on a phone (the default
  // test font draws every letter as a wide square).
  setUpAll(() async {
    final loader = FontLoader('NanumSquareRound');
    for (final w in ['R', 'B', 'EB']) {
      final bytes = File('assets/fonts/NanumSquareRound$w.ttf')
          .readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  });

  testWidgets('onboarding renders on a small phone with large text', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 640) * 3;
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final state = AppState(MemoryCoachRepository(), clock: () => now);
    await state.load();
    await state.updateSettings(state.settings.copyWith(language: () => 'ko'));
    await tester.pumpWidget(CoachApp(state: state));
    _step = 'onboarding';
    await settle(tester);
    await scrollAll(tester);
    // Consent, then on to the goal step.
    await tester.tap(find.byType(Checkbox).first);
    await settle(tester);
    await tester.tap(find.text('시작해볼까요?'));
    await settle(tester);
    await scrollAll(tester);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });

  for (final (name, size, textScale) in [
    ('small phone', const Size(320, 640), 1.0),
    ('big phone', const Size(430, 932), 1.0),
    ('large text', const Size(390, 844), 1.3),
  ]) {
    testWidgets('screens render: $name', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      // Where a layout error happened (the widget may be gone by the time
      // the test looks), printed with the step.
      final original = FlutterError.onError;
      FlutterError.onError = (d) {
        final where = RegExp(r'file:///\S+/lib/\S+').firstMatch(d.toString());
        debugPrint(
          'LAYOUT ${_step ?? 'start'}: ${d.exceptionAsString().split('\n').first} @ ${where?.group(0)}',
        );
        original?.call(d);
      };
      addTearDown(() => FlutterError.onError = original);

      final state = AppState(MemoryCoachRepository(), clock: () => now);
      await state.load();
      // ignore: invalid_use_of_visible_for_testing_member
      await state.loadDemoData(korean: true);
      await state.updateSettings(
        // Korean, and no review question popping up over the screens.
        state.settings.copyWith(language: () => 'ko', reviewAnswered: true),
      );
      final community = CommunityState(
        MemoryCommunity.demo(me: 'me', meJoined: true, clock: () => now),
      );

      await tester.pumpWidget(CoachApp(state: state, community: community));
      await settle(tester);

      Future<void> tab(String label) async {
        _step = 'tab $label';
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text(label),
          ),
        );
        await settle(tester);
      }

      // 오늘 (scrolled to the bottom too)
      await scrollAll(tester);
      await tab('트렌드');
      await scrollAll(tester);
      await tab('체크인');
      await scrollAll(tester);
      await tab('설정');
      await scrollAll(tester);
      await tab('커뮤니티');
      await scrollAll(tester);
      _step = 'lounge';
      await tester.tap(find.text('운동 라운지').first);
      await settle(tester);
      // The lounge opens first and was scrolled down above: back to its top.
      await tester.drag(
        find.byType(Scrollable).first,
        const Offset(0, 4000),
        warnIfMissed: false,
      );
      await settle(tester);

      // A lounge board, then the rest of the lounge.
      _step = 'running board';
      await tester.tap(find.text('러닝').first);
      await settle(tester);
      await scrollAll(tester);
      _step = 'back from board';
      // The board's own back arrow (pageBack finds more than one with the
      // tab's navigator underneath).
      await tester.tap(find.byType(BackButton).last);
      await settle(tester);
      await scrollAll(tester);

      // 알림 and 내 활동 from the top of the tab.
      for (final tip in ['알림', '내 활동']) {
        _step = tip;
        await tester.tap(find.byTooltip(tip).first);
        await settle(tester);
        await scrollAll(tester);
        await tester.tap(find.byType(BackButton).last);
        await settle(tester);
      }

      // Back to 오늘: the meal sheet.
      await tab('오늘');
      _step = 'meal sheet';
      final add = find.text('식사 기록');
      if (add.evaluate().isNotEmpty) {
        await tester.tap(add.first);
        await settle(tester);
      }

      await tester.pumpWidget(const SizedBox());
      community.dispose();
      await tester.pump(const Duration(seconds: 5));
    });
  }
}

// (onboarding runs in its own test below)

/// Lets animations and short delays run out (no pumpAndSettle: some
/// widgets animate forever).
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 150));
    final e = tester.takeException();
    if (e != null) fail('${_step ?? 'start'}: $e');
  }
}

/// What the test was doing, for the failure message.
String? _step;

/// Drags every scrollable on screen to its end, a screen at a time.
Future<void> scrollAll(WidgetTester tester) async {
  _step = '${_step ?? 'start'} (scrolled)';
  final scrollables = find.byType(Scrollable);
  for (var n = 0; n < 6; n++) {
    final list = scrollables.evaluate().toList();
    if (list.isEmpty) return;
    final first = find.byWidget(list.first.widget);
    if (first.evaluate().isEmpty) return;
    await tester.drag(first.first, const Offset(0, -500), warnIfMissed: false);
    await settle(tester);
  }
}
