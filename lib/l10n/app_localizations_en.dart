// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class LEn extends L {
  LEn([String locale = 'en']) : super(locale);

  @override
  String get appName => '알아서핏';

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
  String likeLabel(String n) {
    return 'Like, $n';
  }

  @override
  String addPhotos(String n, String max) {
    return 'Add photos ($n/$max)';
  }

  @override
  String get prevDay => 'Previous day';

  @override
  String get nextDay => 'Next day';

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
      'Log body fat every 1–2 weeks (same device, morning, fasted) and the app tells fat from muscle in your change, tuning calories and protein more precisely.';

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
  String get stepResultIssues => 'Let\'s check the goal again';

  @override
  String get stepResultTitleEdit => 'Here\'s your new plan!';

  @override
  String get resultNoteLearned =>
      'Based on the burn your logs have shown so far. It keeps adapting every week.';

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
  String get bodyFatField => 'Body fat';

  @override
  String get smmField => 'Skeletal muscle';

  @override
  String get moreBodyComp => 'Add body composition';

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
  String get chartHint => 'Tap or drag the chart to see each day';

  @override
  String get tipWeight => 'Weight';

  @override
  String get tipTrend => 'Trend';

  @override
  String get tipIntake => 'Eaten';

  @override
  String get tipWorkout => 'Workout';

  @override
  String get tipNone => 'Not logged';

  @override
  String tipMinutes(String n) {
    return '$n min';
  }

  @override
  String get sugar => 'Sugars';

  @override
  String sugarOfLimit(String g, String limit) {
    return '$g / max ${limit}g';
  }

  @override
  String sugarUnknownMeals(String n) {
    return '$n logged items have no sugar info and aren\'t counted';
  }

  @override
  String sugarPer(String g) {
    return 'Sugars ${g}g';
  }

  @override
  String get sugarNone => 'No sugar info';

  @override
  String get satFat => 'Saturated fat';

  @override
  String satFatUnknownMeals(String n) {
    return '$n logged items have no saturated fat info and aren\'t counted';
  }

  @override
  String satFatPer(String g) {
    return 'Saturated fat ${g}g';
  }

  @override
  String get satFatNone => 'No saturated fat info';

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
  String get bodyFat => 'Body fat';

  @override
  String get smm => 'Skeletal muscle';

  @override
  String compSince(String date) {
    return 'since $date';
  }

  @override
  String get compRecent => 'Recent measurements';

  @override
  String get weightDeleted => 'Weigh-in removed';

  @override
  String showAllN(String n) {
    return 'Show all ($n)';
  }

  @override
  String get showLess => 'Show less';

  @override
  String get noWeights => 'No weigh-ins yet. Tap + at the top right.';

  @override
  String get weightRowHint => 'Tap to edit · swipe to delete';

  @override
  String get workoutWeeklyGoal => 'Weekly goal';

  @override
  String workoutGoalValue(String done, String goal) {
    return '$done/$goal';
  }

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
  String get noChange => 'No change';

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
  String get backToToday => 'Today';

  @override
  String get usageAnalytics => 'Share usage data';

  @override
  String get usageAnalyticsDesc =>
      'Anonymous feature usage to improve the app. Never weights, meals or other health data.';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get signInNotice =>
      'Signing in stores your health data (weight, meals) on our server to sync your devices. Deleting your account erases it right away.';

  @override
  String get sectionAccount => 'Account';

  @override
  String get signInTitle => 'Sign in to keep your log';

  @override
  String get signInBody =>
      'Your log is saved to your account, so it carries over to new phones and other devices.';

  @override
  String get signInCta => 'Sign in and sync';

  @override
  String get signInApple => 'Continue with Apple';

  @override
  String get signInGoogle => 'Continue with Google';

  @override
  String get signInKakao => 'Continue with Kakao';

  @override
  String get signInFailed => 'Couldn\'t sign in. Please try again.';

  @override
  String get signInUnavailable => 'Sign-in isn\'t available in this build.';

  @override
  String get haveAccount => 'I have an account · sign in to restore';

  @override
  String get restoringData => 'Loading your saved records…';

  @override
  String get noSavedDataTitle => 'No saved records on this account';

  @override
  String get noSavedDataBody =>
      'Enter your goal, height and weight: they\'re saved to this account and come back on any device.';

  @override
  String get agreeAndStart => 'Agree and continue';

  @override
  String get restoreFailed =>
      'Couldn\'t load your records. Check your connection and try again.';

  @override
  String get syncing => 'Syncing…';

  @override
  String syncedAt(String time) {
    return 'Synced at $time';
  }

  @override
  String get syncFailed => 'Couldn\'t sync. Will retry when online.';

  @override
  String get syncNow => 'Sync now';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutConfirm =>
      'Signing out clears this device. Your log stays in your account and comes back when you sign in again.';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountConfirm =>
      'Permanently delete your account and all your data? This can\'t be undone.';

  @override
  String streakTitle(String days) {
    return '$days-day logging streak!';
  }

  @override
  String get streakZero => 'Log something today to start a streak';

  @override
  String get pickDate => 'Pick a date';

  @override
  String get logCalendarTitle => 'Log calendar';

  @override
  String logCalendarDays(String logged, String total) {
    return '$logged of $total days logged';
  }

  @override
  String logCurrentStreak(String days) {
    return '$days-day streak now';
  }

  @override
  String logLongestStreak(String days) {
    return 'Longest: $days days';
  }

  @override
  String logMissedDays(String days) {
    return '$days days missed';
  }

  @override
  String get logLegendDone => 'Logged';

  @override
  String get logLegendMissed => 'Missed';

  @override
  String get logLegendToday => 'Today';

  @override
  String get logCalendarHint =>
      'Days with a meal, weight or workout logged get a check, days without get an X. Tap a day to open it.';

  @override
  String weekMeals(String n) {
    return 'Meals $n/7 days';
  }

  @override
  String weekWeighs(String n) {
    return '$n weigh-ins';
  }

  @override
  String get weekLogHint =>
      'Log meals on 5+ days and weight 3+ times so check-in can adjust your target';

  @override
  String get weekLogReady => 'Enough data this week for an accurate check-in!';

  @override
  String get editMeal => 'Edit meal';

  @override
  String get mealUpdated => 'Updated';

  @override
  String get searchAgain => 'Search again';

  @override
  String get updateAvailable => 'A new version is available';

  @override
  String get reload => 'Reload';

  @override
  String get updateInStore => 'A new version is out. Update it from the store';

  @override
  String get updateStoreAction => 'Update';

  @override
  String get pressBackAgainToExit => 'Press back again to exit';

  @override
  String get replaceMeal => 'Replace meal';

  @override
  String mealReplaced(String name) {
    return 'Replaced with $name';
  }

  @override
  String get recentMeals => 'Recent';

  @override
  String get savedMealsTitle => 'My meals';

  @override
  String get mealsOnDay => 'Meals that day';

  @override
  String get weightOnDay => 'Weight that day';

  @override
  String get noMealsPast =>
      'Nothing logged that day.\nYou can fill in missed meals below.';

  @override
  String get pastDayGreeting => 'Filling in a past day';

  @override
  String get workoutsTitle => 'Workouts';

  @override
  String get workoutsOnDay => 'Workouts that day';

  @override
  String get logWorkout => 'Log workout';

  @override
  String get noWorkouts => 'No workouts logged yet';

  @override
  String minutesN(String n) {
    return '$n min';
  }

  @override
  String get workoutMinutes => 'Duration';

  @override
  String workoutAdded(String type, String minutes) {
    return 'Logged $minutes min of $type!';
  }

  @override
  String get workoutDeleted => 'Workout removed';

  @override
  String get workoutNoCalories =>
      'Exercise calories aren\'t added to your target. The energy you burn already shows up in your weight trend and your weekly expenditure estimate.';

  @override
  String weekWorkouts(String n) {
    return '$n workouts';
  }

  @override
  String get workoutSuggestTitle => 'Update your training frequency?';

  @override
  String workoutSuggestBody(String strength, String cardio, String planned) {
    return 'Over the last 2 weeks you averaged $strength strength and $cardio cardio sessions a week, but your settings say $planned. Matching your real training makes the formula estimate more accurate.';
  }

  @override
  String get workoutSuggestApply => 'Match my logs';

  @override
  String get workoutSuggestApplied => 'Training frequency updated';

  @override
  String get workoutTrendTitle => 'Training';

  @override
  String get statusDietBreak => 'Diet break';

  @override
  String get stallTitle => 'Your weight has stalled for 3 weeks';

  @override
  String get stallBody => 'Stalls happen to everyone. Pick one of these.';

  @override
  String get stallCheckLogs => '① Check your logs';

  @override
  String get stallCheckLogsBody =>
      'Missing sauces, drinks or snacks make intake look lower than it was. Days under 60% of target:';

  @override
  String get stallNoSuspicious =>
      'No suspicious days in the last 2 weeks. Your logs look complete.';

  @override
  String stallLower(String kcal) {
    return '② Lower the target to $kcal kcal';
  }

  @override
  String stallBreak(String kcal) {
    return '③ Take a 1-2 week break ($kcal kcal maintenance)';
  }

  @override
  String get stallBreakBody =>
      'Eating at maintenance for a bit helps body and mind recover, and progress often resumes better after. The plan picks up again when it ends.';

  @override
  String breakWeeks(String n) {
    return '$n week(s)';
  }

  @override
  String breakActive(String date) {
    return 'Diet break · eat at maintenance until $date';
  }

  @override
  String breakStarted(String date) {
    return 'Break until $date. Next check-in after that.';
  }

  @override
  String get goalReachedTitle => 'You reached your goal weight! 🎉';

  @override
  String get goalReachedBody =>
      'Amazing work. Switch to maintenance to keep it? Your target moves to your burn.';

  @override
  String get goalReachedMaintain => 'Switch to maintenance';

  @override
  String get goalReachedLater => 'Later';

  @override
  String maintainStarted(String kcal) {
    return 'Maintenance on: $kcal kcal a day.';
  }

  @override
  String get notifDay1Title => 'Log today?';

  @override
  String get notifDay1Body =>
      'Even a rough entry keeps your estimate accurate.';

  @override
  String get notifDay3Title => '3 days off';

  @override
  String get notifDay3Body =>
      'Log one meal today and your trend picks up again.';

  @override
  String get notifDay7Title => 'It\'s been a week';

  @override
  String get notifDay7Body => 'Just a weigh-in restarts your coaching.';

  @override
  String get notifDay14Title => 'Start again?';

  @override
  String get notifDay14Body =>
      'We\'ll fit your calorie target to where you are now.';

  @override
  String get notifDay21Title => '3 weeks off';

  @override
  String get notifDay21Body =>
      'It doesn\'t have to be perfect. Start with one meal today.';

  @override
  String get notifDay28Title => 'It\'s been a month';

  @override
  String get notifDay28Body => 'Weigh in once and we\'ll pick up from there.';

  @override
  String get notifLong1Title => 'We\'re here when you\'re ready';

  @override
  String get notifLong1Body =>
      'Come back anytime and we\'ll pick up from there.';

  @override
  String get notifLong2Title => 'Just a weigh-in?';

  @override
  String get notifLong2Body => 'A weigh-in alone gets your trend going again.';

  @override
  String get notifLong3Title => 'A good day to restart';

  @override
  String get notifLong3Body =>
      'We\'ll set a target that fits where you are now.';

  @override
  String get notifCheckinTitle => 'Check-in day';

  @override
  String get notifCheckinBody =>
      'Last week\'s logs will tune this week\'s target.';

  @override
  String get remindersOffer =>
      'Want a gentle nudge when you skip logging? Weekly for the first month, then every two weeks. Turn it off anytime in Settings.';

  @override
  String get remindersYes => 'Yes, remind me';

  @override
  String get remindersNo => 'No thanks';

  @override
  String get remindersTitle => 'Log & check-in reminders';

  @override
  String get remindersDesc =>
      'At 8 pm after 1 and 3 days without logs, weekly for the first month, then every two weeks, and on check-in day';

  @override
  String get remindersOnMsg => 'Reminders on';

  @override
  String get remindersDenied =>
      'Notifications are off. Turn them on in phone Settings → Apps → 알아서핏 → Notifications, then try again';

  @override
  String get remindersUnsupported => 'Reminders work in the app';

  @override
  String get reviewTitle => 'How\'s 알아서핏 going?';

  @override
  String get reviewGood => 'I like it';

  @override
  String get reviewBad => 'Not great';

  @override
  String get reviewThanks => 'Thank you! That means a lot';

  @override
  String get reviewAskStore => 'A store rating helps more people find 알아서핏.';

  @override
  String get reviewRate => 'Rate it';

  @override
  String get reviewLater => 'Later';

  @override
  String get reviewBadTitle => 'What could be better?';

  @override
  String get reviewBadHint => 'Tell us what bothered you and we\'ll work on it';

  @override
  String get reviewSend => 'Send';

  @override
  String get reviewSent => 'Thanks, we\'ll take it to heart';

  @override
  String get reportTitle => 'This week\'s report';

  @override
  String get reportAte => 'Eaten';

  @override
  String reportAteValue(String days, String kcal) {
    return '$kcal kcal/day over $days days';
  }

  @override
  String get reportTrend => 'Weight trend';

  @override
  String reportTrendValue(String delta, String bal, String dir) {
    return '${delta}kg → $bal kcal/day $dir';
  }

  @override
  String get reportDeficit => 'deficit';

  @override
  String get reportSurplus => 'surplus';

  @override
  String get reportObserved => 'Actual burn';

  @override
  String reportObservedValue(
    String intake,
    String sign,
    String bal,
    String obs,
  ) {
    return '$intake $sign $bal = ~$obs kcal';
  }

  @override
  String get reportEstimate => 'Estimated burn';

  @override
  String reportEstimateValue(String formula, String prev, String est) {
    return 'Blended with the formula\'s $formula, at most ±150 kcal a week: $prev → $est kcal';
  }

  @override
  String get reportTarget => 'New target';

  @override
  String reportTargetValue(String est, String gap, String target, String kg) {
    return 'Burn $est - $gap = $target kcal (${kg}kg/week pace)';
  }

  @override
  String reportTargetSurplus(String est, String gap, String target, String kg) {
    return 'Burn $est + $gap = $target kcal (${kg}kg/week pace)';
  }

  @override
  String reportNoObserved(String formula) {
    return 'Under 2 weeks of logs, so burn is the formula\'s $formula kcal. Your own data takes over as logs build up.';
  }

  @override
  String bigEntryTitle(String kcal) {
    return '$kcal kcal, right?';
  }

  @override
  String get bigEntryBody =>
      'That\'s a lot for one entry. Check for an extra digit.';

  @override
  String get bigEntryFix => 'Fix it';

  @override
  String get bigEntryOk => 'Yes, log it';

  @override
  String numberRange(String min, String max) {
    return 'Enter $min–$max';
  }

  @override
  String get reportComp => 'Body composition';

  @override
  String reportCompValue(String fat, String lean, String weeks, String kcal) {
    return 'Fat $fat kg · lean $lean kg (last $weeks wk) → $kcal kcal per kg';
  }

  @override
  String reportCompSmall(String fat, String lean, String weeks, String kcal) {
    return 'Fat $fat kg · lean $lean kg (last $weeks wk) · too small to change $kcal kcal per kg';
  }

  @override
  String get reportBurn => 'Where the burn goes';

  @override
  String reportBurnValue(
    String bmrLabel,
    String bmr,
    String activity,
    String digestion,
  ) {
    return '$bmrLabel $bmr · activity $activity · digestion $digestion kcal';
  }

  @override
  String get burnBmr => 'Resting';

  @override
  String get burnBmrLean => 'Resting (from lean mass)';

  @override
  String get reportCompAdvice => 'Composition coaching';

  @override
  String compLeanLoss(String pct) {
    return '$pct% of the recent loss was lean mass. To keep muscle, the pace is 30% slower and protein is higher.';
  }

  @override
  String compFatGain(String pct) {
    return '$pct% of the recent gain was fat, so the surplus is 30% smaller.';
  }

  @override
  String compRecomp(String fat, String lean) {
    return 'Fat $fat kg, lean $lean kg — the recomposition is working!';
  }

  @override
  String get infoChart =>
      'Dots are each weigh-in; the line is the trend with water and food swings filtered out; the green dashes are your goal. Tap the chart to see that day\'s weight, food and workouts.';

  @override
  String get infoTrend =>
      'Your weigh-ins smoothed out. It\'s closer to the real change than any single day, so the targets use it.';

  @override
  String get infoWeekly =>
      'Trend now minus a week ago. When losing, 0.5–1% of body weight a week is a comfortable pace.';

  @override
  String get infoEta =>
      'Estimated from the last 3–4 weeks\' trend (or your chosen pace). It sharpens as logs build up.';

  @override
  String get infoIntake =>
      'Calories on the days you logged, against the target. Days without logs are left out of the average. Tap a bar for that day.';

  @override
  String get infoSwaps =>
      'Same kind as foods you ate often in the last 4 weeks, with fewer calories per serving and similar protein.';

  @override
  String get infoWorkout =>
      'Strength and cardio sessions and minutes. Workout calories aren\'t added to the target: the energy shows up in your weight change and the weekly burn estimate.';

  @override
  String get infoBodyComp =>
      'Compare body fat and muscle from the same device under the same conditions (morning, fasted). Measured 2+ weeks apart, the check-in splits your change into fat and muscle to fine-tune the target and protein.';

  @override
  String get infoHistory => 'Your weigh-ins and body composition by date.';

  @override
  String get compGuideNone =>
      'Log body fat every 1–2 weeks. Two readings 2+ weeks apart let the check-in split your change into fat and muscle and fine-tune calories, protein and pace.';

  @override
  String compGuideWaiting(String date) {
    return 'Measure again from $date and the body-composition tuning starts (readings need to be 2+ weeks apart).';
  }

  @override
  String compGuideActive(String n) {
    return 'Body composition is in use ($n readings in 8 weeks). Keep measuring every 1–2 weeks: from the third reading the scale\'s noise is filtered out.';
  }

  @override
  String get swapsTitle => 'Lighter swaps';

  @override
  String get swapsDesc =>
      'Same kind as foods you ate often in the last 4 weeks, compared on everything, not just kcal: a similar carb/protein/fat make-up, protein kept, and no more sugars or saturated fat.';

  @override
  String swapCompare(String from, String to) {
    return 'Protein $from→${to}g';
  }

  @override
  String swapCompareSugar(String from, String to, String sFrom, String sTo) {
    return 'Protein $from→${to}g · sugars $sFrom→${sTo}g';
  }

  @override
  String swapTimes(String n) {
    return 'eaten $n×';
  }

  @override
  String swapSaves(String kcal) {
    return '$kcal kcal less per serving';
  }

  @override
  String swapSavesSugar(String kcal, String sugar) {
    return '$kcal kcal and ${sugar}g sugars less per serving';
  }

  @override
  String get patternsTitle => 'Patterns in the last 4 weeks';

  @override
  String patternWeekend(String kcal) {
    return 'Weekends run $kcal kcal/day above weekdays. Planning one weekend meal ahead closes most of the gap.';
  }

  @override
  String patternSnack(String pct, String food) {
    return 'Snacks are $pct% of your calories, mostly \'$food\'. Try half the amount or a protein snack.';
  }

  @override
  String patternSkipBreakfast(String kcal) {
    return 'Days without breakfast total $kcal kcal more. A light breakfast (eggs, yogurt) may help.';
  }

  @override
  String get focusTitle => 'One thing for next week';

  @override
  String focusLogMore(String n) {
    return 'Log meals on 5+ days (this week: $n). That\'s what makes the estimate work.';
  }

  @override
  String focusWeighMore(String n) {
    return 'Weigh in 3+ times (this week: $n). Mornings before eating are most consistent.';
  }

  @override
  String focusKeepTarget(String kcal) {
    return 'You averaged $kcal kcal over target. Hitting the current target matters more than lowering it.';
  }

  @override
  String focusMoreProtein(String g, String target) {
    return 'Protein averaged ${g}g (target ${target}g). Add one protein food to each meal.';
  }

  @override
  String get focusKeepGoing =>
      'Logging and eating are on point. Same again this week!';

  @override
  String get tipMissedYesterday =>
      'Yesterday has no meals. Even a rough entry keeps your estimate accurate.';

  @override
  String tipOverKcal(String kcal) {
    return '$kcal kcal over today. That\'s fine: the weekly average is what counts. Just eat as usual tomorrow.';
  }

  @override
  String tipOverSugar(String g) {
    return 'Sugars are ${g}g over. Swapping one sweet drink or dessert fixes most of it.';
  }

  @override
  String tipOverSatFat(String g) {
    return 'Saturated fat is ${g}g over. Grilled or lean picks beat fried, processed or creamy ones.';
  }

  @override
  String tipProteinLeft(String g, String food, String grams) {
    return '${g}g protein to go. ${grams}g of $food covers most of it.';
  }

  @override
  String tipProteinLeftPlain(String g) {
    return '${g}g protein to go. Add meat, fish, tofu or eggs to your next meal.';
  }

  @override
  String tipLowKcalLeft(String kcal) {
    return '$kcal kcal left. Keep dinner light: vegetables and protein.';
  }

  @override
  String tipMorningPlan(String kcal, String g) {
    return 'Today: $kcal kcal and ${g}g protein. Start each meal with protein.';
  }

  @override
  String get tipOnTrack => 'Right on target so far. Keep it up!';

  @override
  String get intakeTrendTitle => 'Calories eaten';

  @override
  String get intakeAvg => 'Avg eaten';

  @override
  String get intakeAvgTarget => 'Avg target';

  @override
  String get intakeLoggedDays => 'Days logged';

  @override
  String get intakeLegend => 'Eaten';

  @override
  String get intakeTarget => 'Target';

  @override
  String get intakeNotLogged => 'Not logged';

  @override
  String get intakeTapHint =>
      'Tap a bar to see that day (averages count logged days only)';

  @override
  String get workoutThisWeek => 'Last 7 days';

  @override
  String workoutThisWeekValue(String n, String minutes) {
    return '$n · $minutes min';
  }

  @override
  String get workoutAvg4w => '4-week avg';

  @override
  String workoutAvgValue(String n) {
    return '$n/week';
  }

  @override
  String get legendPlanned => 'Planned';

  @override
  String get noWorkoutData => 'Log workouts to see your weekly trend';

  @override
  String tipRest(String days) {
    return '$days days of training in a row! Recovery is part of training, so a rest day is fine.';
  }

  @override
  String tipStrengthForLoss(String target, String days) {
    return 'While losing weight, strength training on $target+ days a week helps keep muscle. (Last 7 days: $days)';
  }

  @override
  String tipMoreThanUsual(String minutes) {
    return '$minutes min more than your 3-week average!';
  }

  @override
  String tipLessThanUsual(String minutes) {
    return '$minutes min less than your 3-week average. Even a short session counts on a busy week.';
  }

  @override
  String tipPlanDone(String sessions) {
    return 'You hit your $sessions planned sessions this week!';
  }

  @override
  String tipPlanRemaining(String planned, String left) {
    return '$left more to reach your $planned planned sessions.';
  }

  @override
  String tipCardioDone(String minutes) {
    return '$minutes min of cardio: WHO\'s 150 min/week recommendation reached!';
  }

  @override
  String tipCardioProgress(String minutes, String left) {
    return '$minutes min of cardio, $left min to WHO\'s 150 min/week.';
  }

  @override
  String get workoutFeedbackTitle => 'This week\'s training';

  @override
  String get minutesField => 'min';

  @override
  String get slotBreakfast => 'Breakfast';

  @override
  String get slotLunch => 'Lunch';

  @override
  String get slotDinner => 'Dinner';

  @override
  String get slotSnack => 'Snacks';

  @override
  String get tabSearch => 'Search';

  @override
  String get searchHint => 'Search foods (e.g. chicken breast)';

  @override
  String get recentFoodsChip => 'Recent';

  @override
  String addMealToSlot(String slot) {
    return 'Log $slot';
  }

  @override
  String get recentSearches => 'Recent searches';

  @override
  String get clearAll => 'Clear all';

  @override
  String macroSummary(String p, String c, String f) {
    return 'Protein ${p}g · Carbs ${c}g · Fat ${f}g';
  }

  @override
  String get noRecentFoods => 'Foods you log from search show up here';

  @override
  String noResults(String query) {
    return 'No results for \'$query\'';
  }

  @override
  String get remoteSearching => 'Searching the full food database (~300k)…';

  @override
  String get remoteSearchFailed =>
      'Couldn\'t reach the full food database. Showing built-in foods only.';

  @override
  String remoteResults(String n) {
    return '$n more from the full food database';
  }

  @override
  String get createFood => 'Create a food';

  @override
  String get createFoodDesc => 'Can\'t find it? Save your own';

  @override
  String get foodMacrosEstimatedNote =>
      '\'Est.\' (~) values aren\'t published by the source; they\'re estimated from similar foods.';

  @override
  String get estimated => 'Est.';

  @override
  String get foodRefNote =>
      'Nutrition values are typical estimates and vary by product and recipe.';

  @override
  String get unitLabel => 'Unit';

  @override
  String get quantity => 'Amount';

  @override
  String addToSlot(String slot) {
    return 'Add to $slot';
  }

  @override
  String removeFromSlot(String slot) {
    return 'Remove from $slot';
  }

  @override
  String get removeShort => 'Remove';

  @override
  String get pickSlot => 'Which meal?';

  @override
  String updateInSlot(String slot) {
    return 'Update in $slot';
  }

  @override
  String addedCount(String n) {
    return '$n added';
  }

  @override
  String get done => 'Done';

  @override
  String get foodName => 'Food name';

  @override
  String get servingLabel => 'Serving name';

  @override
  String get servingGrams => 'Weight g (optional)';

  @override
  String get perServing => 'Nutrition per serving';

  @override
  String customSaved(String name) {
    return 'Saved $name to your foods';
  }

  @override
  String get photoSoonShort => 'Photo analysis is coming soon';

  @override
  String get mealSlotLabel => 'Meal';

  @override
  String addedToSlot(String name, String slot) {
    return '$name → $slot';
  }

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
  String browseMore(String count) {
    return '$count foods in this category. Search by name to find the rest.';
  }

  @override
  String get foodDataSource =>
      'Source: Korea Ministry of Food and Drug Safety (MFDS) Food Nutrient Database';

  @override
  String get foodDataSourceDesc =>
      'Food search nutrition comes from data.go.kr, converted to per 100 g.';

  @override
  String get savedMealsManage => 'Manage my meals';

  @override
  String get navCommunity => 'Community';

  @override
  String get communityTitle => 'Gym community';

  @override
  String get communityIntro =>
      'Find workout mates and share tips with people at your gym';

  @override
  String get myGyms => 'My gyms';

  @override
  String get myGymsEmpty => 'Search for your gym and add it to My gyms';

  @override
  String get gymSearchHint => 'Gym name or area';

  @override
  String gymSearchEmpty(String q) {
    return 'No gyms match \'$q\'';
  }

  @override
  String get addGym => 'Can\'t find it? Add your gym';

  @override
  String get addGymTitle => 'Add a gym';

  @override
  String get gymName => 'Gym name';

  @override
  String get gymAddress => 'Address';

  @override
  String get gymAdded => 'Gym added';

  @override
  String gymMembers(String n) {
    return '$n members';
  }

  @override
  String gymPosts(String n) {
    return '$n posts';
  }

  @override
  String get joinGym => 'Add to my gyms';

  @override
  String get joinedGym => 'My gym';

  @override
  String leftGym(String name) {
    return 'Removed $name from my gyms';
  }

  @override
  String get leaveGym => 'Remove from my gyms';

  @override
  String get boardEmpty => 'No posts yet. Be the first!';

  @override
  String get writePost => 'Write';

  @override
  String get postHint =>
      'Look for workout mates, share equipment or busy-hour tips, ask anything';

  @override
  String get postSubmit => 'Post';

  @override
  String photoLimit(String n) {
    return 'Up to $n photos';
  }

  @override
  String commentsN(String n) {
    return '$n comments';
  }

  @override
  String get commentHint => 'Add a comment';

  @override
  String get noComments => 'Be the first to comment';

  @override
  String get edited => 'edited';

  @override
  String get justNow => 'just now';

  @override
  String minutesAgo(String n) {
    return '${n}m ago';
  }

  @override
  String hoursAgo(String n) {
    return '${n}h ago';
  }

  @override
  String daysAgo(String n) {
    return '${n}d ago';
  }

  @override
  String get report => 'Report';

  @override
  String get reportContentTitle => 'Why are you reporting this?';

  @override
  String get reasonSpam => 'Spam or ads';

  @override
  String get reasonAbuse => 'Abuse or harassment';

  @override
  String get reasonSexual => 'Sexual content';

  @override
  String get reasonPrivacy => 'Personal information';

  @override
  String get reasonOther => 'Something else';

  @override
  String get reported =>
      'Reported. Posts reported by several people are hidden right away and reviewed within 24 hours.';

  @override
  String get blockUser => 'Block this person';

  @override
  String blockConfirm(String name) {
    return 'Block $name? You won\'t see their posts or comments anymore.';
  }

  @override
  String get blockAction => 'Block';

  @override
  String get blocked => 'Blocked';

  @override
  String get deletePostConfirm =>
      'Delete this post? Its photos and comments go too.';

  @override
  String get deleteCommentConfirm => 'Delete this comment?';

  @override
  String get postDeleted => 'Post deleted';

  @override
  String get editPost => 'Edit';

  @override
  String get communitySignIn => 'Sign in to post and comment';

  @override
  String get communitySignInCta => 'Sign in';

  @override
  String get setupTitle => 'Your community nickname';

  @override
  String get nicknameHint => '2-12 letters or numbers';

  @override
  String get nicknameInvalid => 'Use 2-12 letters or numbers';

  @override
  String get nicknameTaken => 'That nickname is taken';

  @override
  String get bannedError =>
      'This account can no longer post for breaking the community rules. Reach us via Settings → Contact us.';

  @override
  String get discardDraftTitle => 'Discard this post?';

  @override
  String get discardDraftBody =>
      'Closing now loses what you wrote and the photos you picked.';

  @override
  String get keepWriting => 'Keep writing';

  @override
  String get discardDraft => 'Discard';

  @override
  String get searchPosts => 'Search posts';

  @override
  String get searchPostsHint => 'Search this board';

  @override
  String searchPostsCount(String n) {
    return '$n found';
  }

  @override
  String searchPostsEmpty(String q) {
    return 'No posts with $q';
  }

  @override
  String get sortNewest => 'Newest';

  @override
  String get sortPopular => 'Popular';

  @override
  String get popularEmpty => 'No liked posts in the last 30 days yet';

  @override
  String get termsOfUse => 'Terms of use';

  @override
  String get readTerms => 'Read the full terms';

  @override
  String get contactUs => 'Contact us';

  @override
  String get contactUsSub => 'Bugs, reports and ideas';

  @override
  String get contactSubject => '알아서핏 feedback';

  @override
  String contactCopied(String email) {
    return 'No mail app, so the address was copied: $email';
  }

  @override
  String get rulesTitle => 'Community rules';

  @override
  String get rulesBody =>
      '· No abuse, harassment, sexual content, or illegal or commercial ads.\n· Don\'t post other people\'s contact details, photos or other personal info.\n· Don\'t pressure anyone to meet or make people uncomfortable.\n· Posts that break the rules are removed without warning and their authors are banned (zero tolerance). Reports are reviewed within 24 hours.';

  @override
  String get agreeRules => 'Agree and start';

  @override
  String get rateLimited => 'Please wait a bit (up to 5 posts per 10 minutes)';

  @override
  String get blockedWordsError =>
      'That includes words that aren\'t allowed. Please edit and try again.';

  @override
  String get badImage => 'Only JPG or PNG photos up to 5 MB';

  @override
  String get communityError => 'Couldn\'t connect. Please try again later.';

  @override
  String get retry => 'Retry';

  @override
  String get tagAll => 'All';

  @override
  String get tagFree => 'Chat';

  @override
  String get tagMate => 'Workout mate';

  @override
  String get tagQuestion => 'Question';

  @override
  String get tagInfo => 'Tips';

  @override
  String get tagReview => 'Review';

  @override
  String get tagHintFree => 'How was your workout today?';

  @override
  String get tagHintMate => 'Add days, times and what you train to find a mate';

  @override
  String get tagHintQuestion => 'Ask as specifically as you can';

  @override
  String get tagHintInfo => 'Busy hours, equipment, events';

  @override
  String get tagHintReview => 'Reviews of PT, equipment or classes';

  @override
  String get chooseTag => 'What\'s it about?';

  @override
  String get heroTitle => 'What\'s happening\nat your gym?';

  @override
  String heroMyGyms(String n) {
    return 'My gyms $n';
  }

  @override
  String heroNewToday(String n) {
    return 'New today $n';
  }

  @override
  String get findGym => 'Find a gym';

  @override
  String get myGymsNews => 'From my gyms';

  @override
  String get feedEmpty => 'Nothing new yet. Say hi first!';

  @override
  String get startTitle => 'Start your gym community';

  @override
  String get startStep1 => 'Search for your gym';

  @override
  String get startStep2 => 'Add it to My gyms';

  @override
  String get startStep3 => 'Find mates and share tips';

  @override
  String get newBadge => 'New';

  @override
  String get authorBadge => 'Author';

  @override
  String get setupSubtitle => 'This is how gym friends will see you';

  @override
  String searchResults(String n) {
    return '$n results';
  }

  @override
  String get replyAction => 'Reply';

  @override
  String replyingTo(String name) {
    return 'Replying to $name';
  }

  @override
  String get replyHint => 'Write a reply';

  @override
  String repliesN(String n) {
    return '$n replies';
  }

  @override
  String get tabMyGyms => 'My gyms';

  @override
  String get tabLounge => 'Lounge';

  @override
  String get loungeTitle => 'Workout lounge';

  @override
  String get loungeSubtitle => 'Talk with everyone, whatever your gym';

  @override
  String get loungeCategories => 'Boards by workout';

  @override
  String get loungeHot => 'Hot this week';

  @override
  String get loungeLatest => 'Latest in the lounge';

  @override
  String get loungeEmpty => 'No posts yet. Be the first!';

  @override
  String get loungeBoardBadge => 'Lounge · open to everyone';

  @override
  String get topicHealth => 'Gym training';

  @override
  String get topicCrossfit => 'CrossFit';

  @override
  String get topicRunning => 'Running';

  @override
  String get topicYoga => 'Yoga';

  @override
  String get topicPilates => 'Pilates';

  @override
  String get topicDiet => 'Diet & meals';

  @override
  String get topicHome => 'Home workout';

  @override
  String get topicSwimming => 'Swimming';

  @override
  String get topicClimbing => 'Climbing';

  @override
  String get topicCycling => 'Cycling';

  @override
  String get topicCombat => 'Boxing & MMA';

  @override
  String get topicFree => 'Free talk';

  @override
  String gymLimitTitle(String max) {
    return 'Up to $max gyms';
  }

  @override
  String gymLimitBody(String name) {
    return 'Remove one to add $name';
  }

  @override
  String get gymLimitError => 'You can keep up to 3 gyms';

  @override
  String get swapGym => 'Swap';

  @override
  String get inviteFriends => 'Invite';

  @override
  String get inviteTitle => 'Work out with friends';

  @override
  String get inviteBody => 'Send a link and friends can join right away';

  @override
  String get inviteApp => 'Invite to the app';

  @override
  String get inviteAppDesc => 'Share 알아서핏 by chat or text';

  @override
  String inviteGym(String name) {
    return 'Invite to $name';
  }

  @override
  String get inviteGymDesc => 'Bring gym friends to this board';

  @override
  String inviteAppText(String link) {
    return 'I\'ve been tracking meals and workouts with 알아서핏 — join me? 💪\n$link';
  }

  @override
  String inviteGymText(String name, String link) {
    return 'Let\'s work out together on the \'$name\' board in 알아서핏 💪\n$link';
  }

  @override
  String get linkCopied => 'Link copied. Paste it to your friend!';

  @override
  String get shareBoard => 'Share';

  @override
  String get chooseTopic => 'Which board?';

  @override
  String get loungeHotEmpty =>
      'No hot posts yet this week. Like the ones you enjoy!';

  @override
  String get allBoards => 'All';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get editProfileSubtitle => 'Your photo and nickname in the community';

  @override
  String get nicknameLabel => 'Nickname';

  @override
  String get choosePhoto => 'Choose photo';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get myProfile => 'My profile';

  @override
  String get favoritesOnly => 'Favorites';

  @override
  String get favoritesHint => 'Tap ☆ on a board to keep your workouts here';

  @override
  String get favoriteAdd => 'Favorite';

  @override
  String get favoriteAdded => 'Added to favorites';

  @override
  String get myActivity => 'My activity';

  @override
  String get myPostsTab => 'My posts';

  @override
  String get myCommentsTab => 'My comments';

  @override
  String get myPostsEmpty => 'No posts yet. Write your first one!';

  @override
  String get myCommentsEmpty => 'No comments yet';

  @override
  String get onPost => 'On';

  @override
  String get postGone => 'This post was deleted or is hidden';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty =>
      'No notifications yet. Post and comment, and news shows up here!';

  @override
  String get someone => 'Someone';

  @override
  String andOthers(String name, String n) {
    return '$name and $n others';
  }

  @override
  String nameSuffix(String name) {
    return '$name';
  }

  @override
  String notifPostLike(String who) {
    return '$who liked your post';
  }

  @override
  String notifComment(String who) {
    return '$who commented on your post';
  }

  @override
  String notifReply(String who) {
    return '$who replied to your comment';
  }

  @override
  String notifCommentLike(String who) {
    return '$who liked your comment';
  }

  @override
  String get notifHot => 'Your post is trending!';

  @override
  String get hotNow => 'Trending now';

  @override
  String get hotBadge => 'HOT';

  @override
  String get notificationsSignIn =>
      'Sign in to get news about your posts and comments';
}
