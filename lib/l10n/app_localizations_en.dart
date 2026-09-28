// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class LEn extends L {
  LEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Adapt';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get confirm => 'OK';

  @override
  String get undo => 'Undo';

  @override
  String get kcal => 'kcal';

  @override
  String get navToday => 'Today';

  @override
  String get navTrend => 'Trend';

  @override
  String get navCheckin => 'Check-in';

  @override
  String get navSettings => 'Settings';

  @override
  String get welcomeTitle => 'The calorie coach that\nadapts every week';

  @override
  String get welcomeBody =>
      'Just log your weight and meals. We work out how much energy you actually burn and re-tune your target every week.';

  @override
  String get disclaimer =>
      'This app does not provide medical advice. If you have a medical condition or are pregnant or nursing, talk to a professional first.';

  @override
  String get consentLabel =>
      'I agree to store health data such as weight and body composition on this device (sensitive data)';

  @override
  String get getStarted => 'Let\'s start';

  @override
  String get tryDemo => 'Look around with sample data first';

  @override
  String get stepGoalTitle => 'What\'s your goal?';

  @override
  String get goalLose => 'Lose weight';

  @override
  String get goalLoseDesc => 'Steadily reduce body weight';

  @override
  String get goalMaintain => 'Maintain';

  @override
  String get goalMaintainDesc => 'Hold your current weight';

  @override
  String get goalGain => 'Gain';

  @override
  String get goalGainDesc => 'Build muscle and weight';

  @override
  String get goalRecomp => 'Recomposition';

  @override
  String get goalRecompDesc => 'Lose fat while keeping muscle';

  @override
  String get stepBodyTitle => 'Tell us about you';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get birthYear => 'Birth year';

  @override
  String get heightCm => 'Height (cm)';

  @override
  String get weightKg => 'Weight (kg)';

  @override
  String get bodyFatOptional => 'Body fat % (opt.)';

  @override
  String get smmOptional => 'Muscle kg (opt.)';

  @override
  String get bodyCompHint =>
      'Measure body composition on the same device under the same conditions (weekly, morning, fasted).';

  @override
  String get stepTargetTitle => 'Set your target';

  @override
  String get targetByWeight => 'Target weight';

  @override
  String get targetByBodyFat => 'Target body fat';

  @override
  String get targetWeightField => 'Target weight (kg)';

  @override
  String get targetBodyFatField => 'Target body fat (%)';

  @override
  String targetBfResult(String kg) {
    return 'Keeping lean mass, that\'s about $kg kg';
  }

  @override
  String get targetBfNeedsCurrent =>
      'Enter your current body fat to use a body-fat target';

  @override
  String get maintainNoTarget =>
      'No target needed for maintenance. We\'ll keep you around your current weight.';

  @override
  String get stepPaceTitle => 'How fast?';

  @override
  String get paceRelaxed => 'Relaxed';

  @override
  String get paceNormal => 'Moderate';

  @override
  String get paceFast => 'Fast';

  @override
  String paceDesc(String kg, String pct) {
    return 'About $kg kg/week ($pct%)';
  }

  @override
  String get paceHint =>
      'Moderate is a good default. Going too fast raises the risk of muscle loss and rebound.';

  @override
  String get stepActivityTitle => 'How often do you train?';

  @override
  String get strength => 'Strength';

  @override
  String get cardio => 'Cardio';

  @override
  String get timesPerWeek => 'per week';

  @override
  String get activityHint =>
      'Only used for the first estimate. After that, your real data takes over.';

  @override
  String get stepResultTitle => 'Here\'s your first plan!';

  @override
  String get dailyTarget => 'Daily target';

  @override
  String get protein => 'Protein';

  @override
  String get carbs => 'Carbs';

  @override
  String get fat => 'Fat';

  @override
  String get estTdee => 'Est. expenditure';

  @override
  String get etaLabel => 'Estimated arrival';

  @override
  String etaWeeks(String min, String max) {
    return 'In about $min–$max weeks';
  }

  @override
  String get etaReached => 'Almost there!';

  @override
  String get etaUnknown => 'Not predictable yet';

  @override
  String floorNotice(String kcal) {
    return 'Raised to the safety floor ($kcal kcal). Consider a slower pace.';
  }

  @override
  String get resultNote =>
      'This first target is a formula estimate. After 2–4 weeks of logging it adapts to you every week.';

  @override
  String get issueUnderage => 'You must be 18 or older to use this app.';

  @override
  String get issueBmiLow =>
      'A weight-loss goal isn\'t available at your current weight. Please choose maintenance.';

  @override
  String get issueTargetBmiLow =>
      'That target is below a healthy range. Please raise it a little.';

  @override
  String get issueTargetDirection =>
      'Target weight doesn\'t match the goal direction.';

  @override
  String get startApp => 'Start';

  @override
  String get todayGreeting => 'One day at a time!';

  @override
  String get kcalLeft => 'kcal left';

  @override
  String get kcalOver => 'over';

  @override
  String eatenOfTarget(String eaten, String target) {
    return '$eaten / $target kcal';
  }

  @override
  String get weightToday => 'Today\'s weight';

  @override
  String get logWeight => 'Log weight';

  @override
  String trendKg(String kg) {
    return 'Trend $kg kg';
  }

  @override
  String get checkinDueBanner =>
      'It\'s check-in time! Review this week\'s target';

  @override
  String get checkinGo => 'Review';

  @override
  String get mealsTitle => 'Today\'s meals';

  @override
  String get noMealsYet => 'Nothing logged yet.\nAdd your first meal below!';

  @override
  String get addMeal => 'Log meal';

  @override
  String get mealDeleted => 'Deleted';

  @override
  String get tabText => 'Text';

  @override
  String get tabSaved => 'My meals';

  @override
  String get tabManual => 'Manual';

  @override
  String get tabPhoto => 'Photo';

  @override
  String get textHint => 'e.g. brown rice 1 bowl, chicken breast 150g, 2 eggs';

  @override
  String get estimate => 'Estimate';

  @override
  String get estimateNote =>
      'Estimated from a small built-in food table. Feel free to edit.';

  @override
  String unmatchedNote(String items) {
    return 'Unknown items were set to 0 kcal: $items';
  }

  @override
  String get mealName => 'Name';

  @override
  String get kcalField => 'Calories (kcal)';

  @override
  String get proteinField => 'Protein (g)';

  @override
  String get carbsField => 'Carbs (g)';

  @override
  String get fatField => 'Fat (g)';

  @override
  String get saveAsMyMeal => 'Also save to My meals';

  @override
  String get addToToday => 'Add';

  @override
  String get noSavedMeals =>
      'No saved meals yet.\nSave meals you eat often to add them in one tap.';

  @override
  String added(String name) {
    return 'Added $name!';
  }

  @override
  String get photoSoon => 'Photo analysis is coming soon';

  @override
  String get photoSoonDesc =>
      'Once the server is connected, one photo will estimate your meal. (Free: 3 per day. Photos are discarded after analysis.)';

  @override
  String get weightTitle => 'Log weight';

  @override
  String get bodyFatField => 'Body fat (%)';

  @override
  String get smmField => 'Skeletal muscle (kg)';

  @override
  String get moreBodyComp => 'Add body composition';

  @override
  String get healthSync => 'Health app sync';

  @override
  String get healthSyncSoon => 'Coming soon on mobile';

  @override
  String get weightSaved => 'Weight saved';

  @override
  String get trendTitle => 'Trend';

  @override
  String get range4w => '4W';

  @override
  String get range12w => '12W';

  @override
  String get rangeAll => 'All';

  @override
  String get legendRaw => 'Weigh-ins';

  @override
  String get legendTrend => 'Trend';

  @override
  String get legendGoal => 'Goal';

  @override
  String get currentTrend => 'Current trend';

  @override
  String get weeklyChange => 'Last 7 days';

  @override
  String get goalWeight => 'Goal weight';

  @override
  String get bodyCompTitle => 'Body composition';

  @override
  String get noBodyComp => 'Enter body composition to see its trend here.';

  @override
  String get muscleWarn =>
      'Skeletal muscle dropped more than measurement error over 4 weeks. Consider a slower pace and check your protein.';

  @override
  String get notEnoughData => 'Log your weight on 2+ days to see the chart';

  @override
  String get weightHistory => 'Weigh-ins';

  @override
  String get trendExplain =>
      'Daily weight bounces with water. The trend line filters that noise to show the real direction.';

  @override
  String get checkinTitle => 'Weekly check-in';

  @override
  String nextCheckin(String date) {
    return 'Next check-in: $date';
  }

  @override
  String get checkinPreview => 'Not check-in day yet, but here\'s a preview';

  @override
  String get avgIntake => 'Avg intake';

  @override
  String lastNDays(String days) {
    return 'last $days days';
  }

  @override
  String get trendChange => 'Trend change';

  @override
  String get confidence => 'Confidence';

  @override
  String get confHigh => 'High';

  @override
  String get confMedium => 'Medium';

  @override
  String get confLow => 'Low';

  @override
  String get currentTarget => 'Current';

  @override
  String get newTarget => 'Proposed';

  @override
  String reasonLowConfidence(String logged, String weighs) {
    return 'Not quite enough data this week (meals $logged/7 days, $weighs weigh-ins), so your target stays. Log meals 5+ days and weight 3+ times to adjust.';
  }

  @override
  String reasonPlateau(String tdee) {
    return 'Your trend has been flat for 2 weeks. It looks like expenditure dropped to about $tdee kcal. Shall we nudge the target down?';
  }

  @override
  String reasonTdeeUp(String tdee) {
    return 'You\'re burning more than expected! Expenditure estimate raised to $tdee kcal.';
  }

  @override
  String reasonTdeeDown(String tdee) {
    return 'Expenditure estimate came down to $tdee kcal. Adjusting your target to match.';
  }

  @override
  String get reasonOnTrack => 'Right on track! Your target barely changes.';

  @override
  String floorHitCheckin(String kcal) {
    return 'Kept at the $kcal kcal safety floor. Consider a slower pace.';
  }

  @override
  String get accept => 'Accept';

  @override
  String get keep => 'Keep';

  @override
  String get adjust => 'Adjust';

  @override
  String get manualKcalTitle => 'Set target calories';

  @override
  String manualKcalFloor(String kcal) {
    return 'Must be at least $kcal kcal';
  }

  @override
  String get appliedAccept => 'New target applied!';

  @override
  String get appliedKeep => 'Keeping your current target';

  @override
  String get appliedManual => 'Custom target applied';

  @override
  String get howCalculated => 'How was this calculated?';

  @override
  String howCalculatedBody(
    String window,
    String intake,
    String delta,
    String obs,
    String formula,
    String est,
  ) {
    return 'Over the last $window days you averaged $intake kcal and your trend changed $delta kg. At ~7,700 kcal per kg, that implies about $obs kcal/day burned. Blended with the formula estimate ($formula kcal) and limited to ±150 kcal per week, we set it to $est kcal.';
  }

  @override
  String noObservedYet(String formula) {
    return 'Not enough data yet, so we use the formula estimate ($formula kcal). About 2 weeks of logging unlocks your real expenditure.';
  }

  @override
  String get planHistory => 'Target history';

  @override
  String get statusInitial => 'Start';

  @override
  String get statusAccepted => 'Accepted';

  @override
  String get statusKept => 'Kept';

  @override
  String get statusManual => 'Custom';

  @override
  String get checkinDone => 'This week\'s check-in is done!';

  @override
  String get checkinDoneDesc =>
      'Keep logging until the next check-in. More data means better estimates.';

  @override
  String get checkinAnyway => 'Recalculate now anyway';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionProfile => 'Profile';

  @override
  String profileSummary(String sex, String age, String height) {
    return '$sex · $age y · $height cm';
  }

  @override
  String get editGoal => 'Change goal';

  @override
  String get editGoalDesc => 'Keeps your logs, updates your goal';

  @override
  String get sectionApp => 'App';

  @override
  String get language => 'Language';

  @override
  String get langSystem => 'System';

  @override
  String get checkinDay => 'Check-in day';

  @override
  String get notifications => 'Check-in reminders';

  @override
  String get notificationsDesc => 'Coming soon on mobile';

  @override
  String get units => 'Units';

  @override
  String get sectionData => 'Data';

  @override
  String get demoData => 'Load sample data';

  @override
  String get demoDataDesc =>
      'Try check-ins and charts with 5 weeks of sample logs';

  @override
  String get demoConfirm =>
      'Your current logs will be replaced with sample data. Continue?';

  @override
  String get demoLoaded => 'Sample data loaded. Check the Check-in tab!';

  @override
  String consentGiven(String date) {
    return 'Sensitive data consent: $date';
  }

  @override
  String get deleteAll => 'Delete all data';

  @override
  String get deleteAllConfirm =>
      'All weights, meals and plans will be erased and you\'ll return to the start. This can\'t be undone.';

  @override
  String get sectionAbout => 'About';

  @override
  String get version => 'Version';

  @override
  String get savedMealsManage => 'Manage my meals';
}
