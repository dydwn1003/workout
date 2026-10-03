import 'package:adapt_coach/data/community.dart';
import 'package:adapt_coach/data/repository.dart';
import 'package:adapt_coach/main.dart';
import 'package:adapt_coach/state/app_state.dart';
import 'package:adapt_coach/state/community_state.dart';
import 'package:adapt_coach/ui/screens/community/gym_board_screen.dart';
import 'package:adapt_coach/ui/screens/community/post_screen.dart';
import 'package:adapt_coach/ui/screens/add_meal_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Android back button goes back one step at a time.
void main() {
  final now = DateTime(2026, 9, 29, 12);

  testWidgets('back in onboarding goes to the step before', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final state = AppState(MemoryCoachRepository(), clock: () => now);
    await state.load();
    await state.updateSettings(state.settings.copyWith(language: () => 'ko'));
    await tester.pumpWidget(CoachApp(state: state));
    await settle(tester);
    await tester.tap(find.byType(Checkbox).first);
    await settle(tester);
    await tester.tap(find.text('시작해볼까요?'));
    await settle(tester);
    expect(find.text('시작해볼까요?'), findsNothing, reason: 'on the goal step');
    final handled = await tester.binding.handlePopRoute();
    await settle(tester);
    expect(handled, isTrue, reason: 'the app did not close');
    expect(find.text('시작해볼까요?'), findsOneWidget, reason: 'welcome again');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('back: post -> board -> lounge, then 오늘', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final state = AppState(MemoryCoachRepository(), clock: () => now);
    await state.load();
    // ignore: invalid_use_of_visible_for_testing_member
    await state.loadDemoData(korean: true);
    await state.updateSettings(
      state.settings.copyWith(language: () => 'ko', reviewAnswered: true),
    );
    final community = CommunityState(
      MemoryCommunity.demo(me: 'me', meJoined: true, clock: () => now),
    );
    await tester.pumpWidget(CoachApp(state: state, community: community));
    await settle(tester);

    Future<void> back() async {
      await tester.binding.handlePopRoute();
      await settle(tester);
    }

    Future<void> tab(String label) async {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
      );
      await settle(tester);
    }

    await tab('커뮤니티');
    await tester.tap(find.text('러닝').first);
    await settle(tester);
    expect(find.byType(GymBoardScreen), findsOneWidget);
    await tester.tap(find.textContaining('한강').first);
    await settle(tester);
    expect(find.byType(PostScreen), findsOneWidget);

    await back();
    expect(find.byType(PostScreen), findsNothing, reason: 'post closes');
    expect(find.byType(GymBoardScreen), findsOneWidget, reason: 'board stays');

    await back();
    expect(find.byType(GymBoardScreen), findsNothing);
    expect(find.text('💪 운동별 게시판'), findsOneWidget, reason: 'still community');

    // Meal sheet: a food's detail -> back -> the list, sheet still open.
    await tab('오늘');
    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester);
    await tester.tap(find.text('아침').last);
    await settle(tester);
    expect(find.byType(AddMealSheet), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '계란');
    await settle(tester);
    await tester.tap(find.text('계란').last);
    await settle(tester);
    expect(find.text('1개 (50g)'), findsWidgets, reason: 'detail open');
    await back();
    expect(find.byType(AddMealSheet), findsOneWidget, reason: 'sheet stays');
    expect(find.text('1개 (50g)'), findsNothing, reason: 'back to list');
    await back();
    expect(find.byType(AddMealSheet), findsNothing, reason: 'then closes');
    await tab('커뮤니티');

    // 내 헬스장 -> back -> 운동 라운지 (still community).
    await tester.tap(find.textContaining('내 헬스장').first);
    await settle(tester);
    expect(find.text('💪 운동별 게시판'), findsNothing);
    await back();
    expect(find.text('💪 운동별 게시판'), findsOneWidget, reason: 'lounge again');

    // Tabs: 커뮤니티 -> 체크인 -> back -> 커뮤니티 -> back -> 오늘.
    await tab('체크인');
    expect(find.text('주간 체크인'), findsWidgets);
    await back();
    expect(
      find.text('💪 운동별 게시판'),
      findsOneWidget,
      reason: 'back to community',
    );
    await back();
    expect(find.text('💪 운동별 게시판'), findsNothing, reason: 'then 오늘');

    await tester.pumpWidget(const SizedBox());
    community.dispose();
    await tester.pump(const Duration(seconds: 5));
  });
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
