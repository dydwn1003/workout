import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L
/// returned by `L.of(context)`.
///
/// Applications need to include `L.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L.localizationsDelegates,
///   supportedLocales: L.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L.supportedLocales
/// property.
abstract class L {
  L(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L of(BuildContext context) {
    return Localizations.of<L>(context, L)!;
  }

  static const LocalizationsDelegate<L> delegate = _LDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @appName.
  ///
  /// In ko, this message translates to:
  /// **'알아서핏'**
  String get appName;

  /// No description provided for @next.
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get next;

  /// No description provided for @back.
  ///
  /// In ko, this message translates to:
  /// **'이전'**
  String get back;

  /// No description provided for @save.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get delete;

  /// No description provided for @confirm.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get confirm;

  /// No description provided for @likeLabel.
  ///
  /// In ko, this message translates to:
  /// **'좋아요 {n}'**
  String likeLabel(String n);

  /// No description provided for @addPhotos.
  ///
  /// In ko, this message translates to:
  /// **'사진 추가 ({n}/{max})'**
  String addPhotos(String n, String max);

  /// No description provided for @prevDay.
  ///
  /// In ko, this message translates to:
  /// **'전날'**
  String get prevDay;

  /// No description provided for @nextDay.
  ///
  /// In ko, this message translates to:
  /// **'다음 날'**
  String get nextDay;

  /// No description provided for @undo.
  ///
  /// In ko, this message translates to:
  /// **'되돌리기'**
  String get undo;

  /// No description provided for @kcal.
  ///
  /// In ko, this message translates to:
  /// **'kcal'**
  String get kcal;

  /// No description provided for @navToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get navToday;

  /// No description provided for @navTrend.
  ///
  /// In ko, this message translates to:
  /// **'트렌드'**
  String get navTrend;

  /// No description provided for @navCheckin.
  ///
  /// In ko, this message translates to:
  /// **'체크인'**
  String get navCheckin;

  /// No description provided for @navSettings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get navSettings;

  /// No description provided for @welcomeTitle.
  ///
  /// In ko, this message translates to:
  /// **'매주 알아서 맞춰주는\n칼로리 코치'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In ko, this message translates to:
  /// **'체중과 식사만 기록하세요. 실제로 쓰는 에너지를 계산해서 매주 목표 칼로리를 다시 맞춰 드릴게요.'**
  String get welcomeBody;

  /// No description provided for @disclaimer.
  ///
  /// In ko, this message translates to:
  /// **'이 앱은 의학적 조언을 제공하지 않아요. 질환이 있거나 임신·수유 중이라면 먼저 전문가와 상담해 주세요.'**
  String get disclaimer;

  /// No description provided for @consentLabel.
  ///
  /// In ko, this message translates to:
  /// **'체중·체성분 같은 건강 정보를 이 기기에 저장하는 데 동의해요 (민감정보)'**
  String get consentLabel;

  /// No description provided for @getStarted.
  ///
  /// In ko, this message translates to:
  /// **'시작해볼까요?'**
  String get getStarted;

  /// No description provided for @stepGoalTitle.
  ///
  /// In ko, this message translates to:
  /// **'어떤 목표를 가지고 있나요?'**
  String get stepGoalTitle;

  /// No description provided for @goalLose.
  ///
  /// In ko, this message translates to:
  /// **'감량'**
  String get goalLose;

  /// No description provided for @goalLoseDesc.
  ///
  /// In ko, this message translates to:
  /// **'체중을 천천히 줄여요'**
  String get goalLoseDesc;

  /// No description provided for @goalMaintain.
  ///
  /// In ko, this message translates to:
  /// **'유지'**
  String get goalMaintain;

  /// No description provided for @goalMaintainDesc.
  ///
  /// In ko, this message translates to:
  /// **'지금 체중을 지켜요'**
  String get goalMaintainDesc;

  /// No description provided for @goalGain.
  ///
  /// In ko, this message translates to:
  /// **'증량'**
  String get goalGain;

  /// No description provided for @goalGainDesc.
  ///
  /// In ko, this message translates to:
  /// **'근육과 체중을 늘려요'**
  String get goalGainDesc;

  /// No description provided for @goalRecomp.
  ///
  /// In ko, this message translates to:
  /// **'체성분 개선'**
  String get goalRecomp;

  /// No description provided for @goalRecompDesc.
  ///
  /// In ko, this message translates to:
  /// **'체지방은 줄이고 근육은 지켜요'**
  String get goalRecompDesc;

  /// No description provided for @stepBodyTitle.
  ///
  /// In ko, this message translates to:
  /// **'지금 몸 상태를 알려주세요'**
  String get stepBodyTitle;

  /// No description provided for @male.
  ///
  /// In ko, this message translates to:
  /// **'남성'**
  String get male;

  /// No description provided for @female.
  ///
  /// In ko, this message translates to:
  /// **'여성'**
  String get female;

  /// No description provided for @birthYear.
  ///
  /// In ko, this message translates to:
  /// **'출생연도'**
  String get birthYear;

  /// No description provided for @heightCm.
  ///
  /// In ko, this message translates to:
  /// **'키 (cm)'**
  String get heightCm;

  /// No description provided for @weightKg.
  ///
  /// In ko, this message translates to:
  /// **'체중 (kg)'**
  String get weightKg;

  /// No description provided for @bodyFatOptional.
  ///
  /// In ko, this message translates to:
  /// **'체지방 %(선택)'**
  String get bodyFatOptional;

  /// No description provided for @smmOptional.
  ///
  /// In ko, this message translates to:
  /// **'골격근 kg(선택)'**
  String get smmOptional;

  /// No description provided for @bodyCompHint.
  ///
  /// In ko, this message translates to:
  /// **'체지방률을 1~2주에 한 번(같은 기기, 아침 공복) 재서 넣으면 빠진 체중이 지방인지 근육인지 나눠서, 섭취 칼로리와 단백질을 더 정확하게 맞춰 드려요.'**
  String get bodyCompHint;

  /// No description provided for @stepTargetTitle.
  ///
  /// In ko, this message translates to:
  /// **'목표를 정해볼까요?'**
  String get stepTargetTitle;

  /// No description provided for @targetByWeight.
  ///
  /// In ko, this message translates to:
  /// **'목표 체중'**
  String get targetByWeight;

  /// No description provided for @targetByBodyFat.
  ///
  /// In ko, this message translates to:
  /// **'목표 체지방률'**
  String get targetByBodyFat;

  /// No description provided for @targetWeightField.
  ///
  /// In ko, this message translates to:
  /// **'목표 체중 (kg)'**
  String get targetWeightField;

  /// No description provided for @targetBodyFatField.
  ///
  /// In ko, this message translates to:
  /// **'목표 체지방률 (%)'**
  String get targetBodyFatField;

  /// No description provided for @targetBfResult.
  ///
  /// In ko, this message translates to:
  /// **'근육(제지방량)을 유지하면 목표 체중은 약 {kg}kg이에요'**
  String targetBfResult(String kg);

  /// No description provided for @targetBfNeedsCurrent.
  ///
  /// In ko, this message translates to:
  /// **'체지방률 목표는 현재 체지방률을 입력해야 쓸 수 있어요'**
  String get targetBfNeedsCurrent;

  /// No description provided for @maintainNoTarget.
  ///
  /// In ko, this message translates to:
  /// **'유지 목표는 따로 목표값이 필요 없어요. 지금 체중 근처를 지켜드릴게요.'**
  String get maintainNoTarget;

  /// No description provided for @stepPaceTitle.
  ///
  /// In ko, this message translates to:
  /// **'어떤 속도로 갈까요?'**
  String get stepPaceTitle;

  /// No description provided for @paceRelaxed.
  ///
  /// In ko, this message translates to:
  /// **'여유롭게'**
  String get paceRelaxed;

  /// No description provided for @paceNormal.
  ///
  /// In ko, this message translates to:
  /// **'보통'**
  String get paceNormal;

  /// No description provided for @paceFast.
  ///
  /// In ko, this message translates to:
  /// **'빠르게'**
  String get paceFast;

  /// No description provided for @paceDesc.
  ///
  /// In ko, this message translates to:
  /// **'주당 약 {kg}kg ({pct}%)'**
  String paceDesc(String kg, String pct);

  /// No description provided for @paceHint.
  ///
  /// In ko, this message translates to:
  /// **'처음이라면 \'보통\'을 추천해요. 너무 빠르면 근손실과 요요 위험이 커져요.'**
  String get paceHint;

  /// No description provided for @stepActivityTitle.
  ///
  /// In ko, this message translates to:
  /// **'일주일에 운동을 얼마나 하나요?'**
  String get stepActivityTitle;

  /// No description provided for @strength.
  ///
  /// In ko, this message translates to:
  /// **'근력운동'**
  String get strength;

  /// No description provided for @cardio.
  ///
  /// In ko, this message translates to:
  /// **'유산소'**
  String get cardio;

  /// No description provided for @timesPerWeek.
  ///
  /// In ko, this message translates to:
  /// **'회 / 주'**
  String get timesPerWeek;

  /// No description provided for @activityHint.
  ///
  /// In ko, this message translates to:
  /// **'처음 목표를 계산할 때만 써요. 이후엔 실제 기록으로 맞춰져요.'**
  String get activityHint;

  /// No description provided for @stepResultTitle.
  ///
  /// In ko, this message translates to:
  /// **'첫 번째 목표가 나왔어요!'**
  String get stepResultTitle;

  /// No description provided for @dailyTarget.
  ///
  /// In ko, this message translates to:
  /// **'하루 목표'**
  String get dailyTarget;

  /// No description provided for @protein.
  ///
  /// In ko, this message translates to:
  /// **'단백질'**
  String get protein;

  /// No description provided for @carbs.
  ///
  /// In ko, this message translates to:
  /// **'탄수화물'**
  String get carbs;

  /// No description provided for @fat.
  ///
  /// In ko, this message translates to:
  /// **'지방'**
  String get fat;

  /// No description provided for @estTdee.
  ///
  /// In ko, this message translates to:
  /// **'추정 소비량'**
  String get estTdee;

  /// No description provided for @etaLabel.
  ///
  /// In ko, this message translates to:
  /// **'목표 도달 예상'**
  String get etaLabel;

  /// No description provided for @etaWeeks.
  ///
  /// In ko, this message translates to:
  /// **'약 {min}~{max}주 후'**
  String etaWeeks(String min, String max);

  /// No description provided for @etaReached.
  ///
  /// In ko, this message translates to:
  /// **'거의 도착했어요!'**
  String get etaReached;

  /// No description provided for @etaUnknown.
  ///
  /// In ko, this message translates to:
  /// **'아직 예측하기 어려워요'**
  String get etaUnknown;

  /// No description provided for @floorNotice.
  ///
  /// In ko, this message translates to:
  /// **'안전 하한({kcal} kcal)에 맞췄어요. 속도를 한 단계 낮추는 걸 추천해요.'**
  String floorNotice(String kcal);

  /// No description provided for @stepResultIssues.
  ///
  /// In ko, this message translates to:
  /// **'목표를 다시 확인해 주세요'**
  String get stepResultIssues;

  /// No description provided for @stepResultTitleEdit.
  ///
  /// In ko, this message translates to:
  /// **'새 목표가 나왔어요!'**
  String get stepResultTitleEdit;

  /// No description provided for @resultNoteLearned.
  ///
  /// In ko, this message translates to:
  /// **'지금까지 기록으로 계산한 실제 소비량으로 맞췄어요. 앞으로도 매주 조정돼요.'**
  String get resultNoteLearned;

  /// No description provided for @resultNote.
  ///
  /// In ko, this message translates to:
  /// **'첫 목표는 공식으로 계산한 추정치예요. 2~4주 기록이 쌓이면 내 몸에 맞게 매주 조정돼요.'**
  String get resultNote;

  /// No description provided for @issueUnderage.
  ///
  /// In ko, this message translates to:
  /// **'만 18세 미만은 사용할 수 없어요.'**
  String get issueUnderage;

  /// No description provided for @issueBmiLow.
  ///
  /// In ko, this message translates to:
  /// **'현재 체중에서는 감량 목표를 만들 수 없어요. 유지를 선택해 주세요.'**
  String get issueBmiLow;

  /// No description provided for @issueTargetBmiLow.
  ///
  /// In ko, this message translates to:
  /// **'목표 체중이 건강 범위보다 낮아요. 목표를 조금 올려주세요.'**
  String get issueTargetBmiLow;

  /// No description provided for @issueTargetDirection.
  ///
  /// In ko, this message translates to:
  /// **'목표 체중이 선택한 목표와 방향이 맞지 않아요.'**
  String get issueTargetDirection;

  /// No description provided for @startApp.
  ///
  /// In ko, this message translates to:
  /// **'시작하기'**
  String get startApp;

  /// No description provided for @todayGreeting.
  ///
  /// In ko, this message translates to:
  /// **'오늘도 차근차근!'**
  String get todayGreeting;

  /// No description provided for @kcalLeft.
  ///
  /// In ko, this message translates to:
  /// **'남은 칼로리'**
  String get kcalLeft;

  /// No description provided for @kcalOver.
  ///
  /// In ko, this message translates to:
  /// **'초과'**
  String get kcalOver;

  /// No description provided for @eatenOfTarget.
  ///
  /// In ko, this message translates to:
  /// **'{eaten} / {target} kcal'**
  String eatenOfTarget(String eaten, String target);

  /// No description provided for @weightToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘 체중'**
  String get weightToday;

  /// No description provided for @logWeight.
  ///
  /// In ko, this message translates to:
  /// **'체중 기록하기'**
  String get logWeight;

  /// No description provided for @trendKg.
  ///
  /// In ko, this message translates to:
  /// **'추세 {kg}kg'**
  String trendKg(String kg);

  /// No description provided for @checkinDueBanner.
  ///
  /// In ko, this message translates to:
  /// **'주간 체크인 시간이에요! 이번 주 목표를 확인해 보세요'**
  String get checkinDueBanner;

  /// No description provided for @checkinGo.
  ///
  /// In ko, this message translates to:
  /// **'확인하기'**
  String get checkinGo;

  /// No description provided for @mealsTitle.
  ///
  /// In ko, this message translates to:
  /// **'오늘 먹은 것'**
  String get mealsTitle;

  /// No description provided for @noMealsYet.
  ///
  /// In ko, this message translates to:
  /// **'아직 기록이 없어요.\n아래 버튼으로 첫 끼를 남겨보세요!'**
  String get noMealsYet;

  /// No description provided for @addMeal.
  ///
  /// In ko, this message translates to:
  /// **'식사 기록'**
  String get addMeal;

  /// No description provided for @mealDeleted.
  ///
  /// In ko, this message translates to:
  /// **'삭제했어요'**
  String get mealDeleted;

  /// No description provided for @tabText.
  ///
  /// In ko, this message translates to:
  /// **'텍스트'**
  String get tabText;

  /// No description provided for @tabSaved.
  ///
  /// In ko, this message translates to:
  /// **'내 식사'**
  String get tabSaved;

  /// No description provided for @tabManual.
  ///
  /// In ko, this message translates to:
  /// **'직접 입력'**
  String get tabManual;

  /// No description provided for @tabPhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진'**
  String get tabPhoto;

  /// No description provided for @textHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 현미밥 1공기, 닭가슴살 150g, 계란 2개'**
  String get textHint;

  /// No description provided for @estimate.
  ///
  /// In ko, this message translates to:
  /// **'계산하기'**
  String get estimate;

  /// No description provided for @estimateNote.
  ///
  /// In ko, this message translates to:
  /// **'간이 음식 사전으로 추정했어요. 값은 자유롭게 고칠 수 있어요.'**
  String get estimateNote;

  /// No description provided for @unmatchedNote.
  ///
  /// In ko, this message translates to:
  /// **'모르는 음식은 0 kcal로 두었어요: {items}'**
  String unmatchedNote(String items);

  /// No description provided for @mealName.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get mealName;

  /// No description provided for @kcalField.
  ///
  /// In ko, this message translates to:
  /// **'칼로리 (kcal)'**
  String get kcalField;

  /// No description provided for @proteinField.
  ///
  /// In ko, this message translates to:
  /// **'단백질 (g)'**
  String get proteinField;

  /// No description provided for @carbsField.
  ///
  /// In ko, this message translates to:
  /// **'탄수 (g)'**
  String get carbsField;

  /// No description provided for @fatField.
  ///
  /// In ko, this message translates to:
  /// **'지방 (g)'**
  String get fatField;

  /// No description provided for @saveAsMyMeal.
  ///
  /// In ko, this message translates to:
  /// **'\'내 식사\'에도 저장하기'**
  String get saveAsMyMeal;

  /// No description provided for @addToToday.
  ///
  /// In ko, this message translates to:
  /// **'추가하기'**
  String get addToToday;

  /// No description provided for @noSavedMeals.
  ///
  /// In ko, this message translates to:
  /// **'저장된 식사가 없어요.\n자주 먹는 식사를 저장하면 한 번에 추가할 수 있어요.'**
  String get noSavedMeals;

  /// No description provided for @added.
  ///
  /// In ko, this message translates to:
  /// **'{name} 추가!'**
  String added(String name);

  /// No description provided for @photoSoon.
  ///
  /// In ko, this message translates to:
  /// **'사진 분석은 곧 만나요'**
  String get photoSoon;

  /// No description provided for @photoSoonDesc.
  ///
  /// In ko, this message translates to:
  /// **'서버가 연결되면 사진 한 장으로 음식과 칼로리를 추정해 드릴게요. (무료 하루 3장, 사진은 분석 후 바로 폐기)'**
  String get photoSoonDesc;

  /// No description provided for @weightTitle.
  ///
  /// In ko, this message translates to:
  /// **'체중 기록'**
  String get weightTitle;

  /// No description provided for @bodyFatField.
  ///
  /// In ko, this message translates to:
  /// **'체지방률'**
  String get bodyFatField;

  /// No description provided for @smmField.
  ///
  /// In ko, this message translates to:
  /// **'골격근량'**
  String get smmField;

  /// No description provided for @moreBodyComp.
  ///
  /// In ko, this message translates to:
  /// **'체성분도 입력하기'**
  String get moreBodyComp;

  /// No description provided for @weightSaved.
  ///
  /// In ko, this message translates to:
  /// **'체중을 기록했어요'**
  String get weightSaved;

  /// No description provided for @trendTitle.
  ///
  /// In ko, this message translates to:
  /// **'트렌드'**
  String get trendTitle;

  /// No description provided for @range4w.
  ///
  /// In ko, this message translates to:
  /// **'4주'**
  String get range4w;

  /// No description provided for @range12w.
  ///
  /// In ko, this message translates to:
  /// **'12주'**
  String get range12w;

  /// No description provided for @rangeAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get rangeAll;

  /// No description provided for @chartHint.
  ///
  /// In ko, this message translates to:
  /// **'그래프를 누르거나 좌우로 밀면 날짜별 기록을 볼 수 있어요'**
  String get chartHint;

  /// No description provided for @tipWeight.
  ///
  /// In ko, this message translates to:
  /// **'체중'**
  String get tipWeight;

  /// No description provided for @tipTrend.
  ///
  /// In ko, this message translates to:
  /// **'추세'**
  String get tipTrend;

  /// No description provided for @tipIntake.
  ///
  /// In ko, this message translates to:
  /// **'섭취'**
  String get tipIntake;

  /// No description provided for @tipWorkout.
  ///
  /// In ko, this message translates to:
  /// **'운동'**
  String get tipWorkout;

  /// No description provided for @tipNone.
  ///
  /// In ko, this message translates to:
  /// **'기록 없음'**
  String get tipNone;

  /// No description provided for @tipMinutes.
  ///
  /// In ko, this message translates to:
  /// **'{n}분'**
  String tipMinutes(String n);

  /// No description provided for @sugar.
  ///
  /// In ko, this message translates to:
  /// **'당류'**
  String get sugar;

  /// No description provided for @sugarOfLimit.
  ///
  /// In ko, this message translates to:
  /// **'{g} / 최대 {limit}g'**
  String sugarOfLimit(String g, String limit);

  /// No description provided for @sugarUnknownMeals.
  ///
  /// In ko, this message translates to:
  /// **'당류 정보가 없는 기록 {n}개는 빠져 있어요'**
  String sugarUnknownMeals(String n);

  /// No description provided for @sugarPer.
  ///
  /// In ko, this message translates to:
  /// **'당류 {g}g'**
  String sugarPer(String g);

  /// No description provided for @sugarNone.
  ///
  /// In ko, this message translates to:
  /// **'당류 정보 없음'**
  String get sugarNone;

  /// No description provided for @satFat.
  ///
  /// In ko, this message translates to:
  /// **'포화지방'**
  String get satFat;

  /// No description provided for @satFatUnknownMeals.
  ///
  /// In ko, this message translates to:
  /// **'포화지방 정보가 없는 기록 {n}개는 빠져 있어요'**
  String satFatUnknownMeals(String n);

  /// No description provided for @satFatPer.
  ///
  /// In ko, this message translates to:
  /// **'포화지방 {g}g'**
  String satFatPer(String g);

  /// No description provided for @satFatNone.
  ///
  /// In ko, this message translates to:
  /// **'포화지방 정보 없음'**
  String get satFatNone;

  /// No description provided for @legendRaw.
  ///
  /// In ko, this message translates to:
  /// **'측정값'**
  String get legendRaw;

  /// No description provided for @legendTrend.
  ///
  /// In ko, this message translates to:
  /// **'추세'**
  String get legendTrend;

  /// No description provided for @legendGoal.
  ///
  /// In ko, this message translates to:
  /// **'목표'**
  String get legendGoal;

  /// No description provided for @currentTrend.
  ///
  /// In ko, this message translates to:
  /// **'현재 추세'**
  String get currentTrend;

  /// No description provided for @weeklyChange.
  ///
  /// In ko, this message translates to:
  /// **'지난 7일'**
  String get weeklyChange;

  /// No description provided for @goalWeight.
  ///
  /// In ko, this message translates to:
  /// **'목표 체중'**
  String get goalWeight;

  /// No description provided for @bodyCompTitle.
  ///
  /// In ko, this message translates to:
  /// **'체성분 추이'**
  String get bodyCompTitle;

  /// No description provided for @noBodyComp.
  ///
  /// In ko, this message translates to:
  /// **'체성분을 입력하면 여기서 추이를 볼 수 있어요.'**
  String get noBodyComp;

  /// No description provided for @muscleWarn.
  ///
  /// In ko, this message translates to:
  /// **'최근 4주간 골격근량이 측정 오차보다 크게 줄었어요. 감량 속도를 낮추고 단백질 섭취를 확인해 보세요.'**
  String get muscleWarn;

  /// No description provided for @notEnoughData.
  ///
  /// In ko, this message translates to:
  /// **'체중을 2일 이상 기록하면 그래프가 나타나요'**
  String get notEnoughData;

  /// No description provided for @weightHistory.
  ///
  /// In ko, this message translates to:
  /// **'체중 기록'**
  String get weightHistory;

  /// No description provided for @bodyFat.
  ///
  /// In ko, this message translates to:
  /// **'체지방률'**
  String get bodyFat;

  /// No description provided for @smm.
  ///
  /// In ko, this message translates to:
  /// **'골격근량'**
  String get smm;

  /// No description provided for @compSince.
  ///
  /// In ko, this message translates to:
  /// **'{date}보다'**
  String compSince(String date);

  /// No description provided for @compPointDate.
  ///
  /// In ko, this message translates to:
  /// **'{date} 측정'**
  String compPointDate(String date);

  /// No description provided for @compFirstOnly.
  ///
  /// In ko, this message translates to:
  /// **'다음 측정부터 변화가 그려져요'**
  String get compFirstOnly;

  /// No description provided for @compRecent.
  ///
  /// In ko, this message translates to:
  /// **'최근 측정'**
  String get compRecent;

  /// No description provided for @weightDeleted.
  ///
  /// In ko, this message translates to:
  /// **'체중 기록을 지웠어요'**
  String get weightDeleted;

  /// No description provided for @showAllN.
  ///
  /// In ko, this message translates to:
  /// **'전체 보기 ({n})'**
  String showAllN(String n);

  /// No description provided for @showLess.
  ///
  /// In ko, this message translates to:
  /// **'접기'**
  String get showLess;

  /// No description provided for @noWeights.
  ///
  /// In ko, this message translates to:
  /// **'아직 체중 기록이 없어요. 오른쪽 위 + 로 기록해 보세요.'**
  String get noWeights;

  /// No description provided for @weightRowHint.
  ///
  /// In ko, this message translates to:
  /// **'눌러서 수정 · 옆으로 밀어서 삭제'**
  String get weightRowHint;

  /// No description provided for @workoutWeeklyGoal.
  ///
  /// In ko, this message translates to:
  /// **'주간 목표 달성'**
  String get workoutWeeklyGoal;

  /// No description provided for @workoutGoalValue.
  ///
  /// In ko, this message translates to:
  /// **'{done}/{goal}회'**
  String workoutGoalValue(String done, String goal);

  /// No description provided for @trendExplain.
  ///
  /// In ko, this message translates to:
  /// **'매일 체중은 수분 때문에 오르락내리락해요. 추세선은 그 흔들림을 걸러낸 진짜 방향이에요.'**
  String get trendExplain;

  /// No description provided for @checkinTitle.
  ///
  /// In ko, this message translates to:
  /// **'주간 체크인'**
  String get checkinTitle;

  /// No description provided for @nextCheckin.
  ///
  /// In ko, this message translates to:
  /// **'다음 체크인: {date}'**
  String nextCheckin(String date);

  /// No description provided for @checkinPreview.
  ///
  /// In ko, this message translates to:
  /// **'아직 체크인 날은 아니지만 미리 볼 수 있어요'**
  String get checkinPreview;

  /// No description provided for @avgIntake.
  ///
  /// In ko, this message translates to:
  /// **'평균 섭취'**
  String get avgIntake;

  /// No description provided for @lastNDays.
  ///
  /// In ko, this message translates to:
  /// **'최근 {days}일'**
  String lastNDays(String days);

  /// No description provided for @trendChange.
  ///
  /// In ko, this message translates to:
  /// **'추세 체중 변화'**
  String get trendChange;

  /// No description provided for @confidence.
  ///
  /// In ko, this message translates to:
  /// **'신뢰도'**
  String get confidence;

  /// No description provided for @confHigh.
  ///
  /// In ko, this message translates to:
  /// **'높음'**
  String get confHigh;

  /// No description provided for @confMedium.
  ///
  /// In ko, this message translates to:
  /// **'보통'**
  String get confMedium;

  /// No description provided for @confLow.
  ///
  /// In ko, this message translates to:
  /// **'낮음'**
  String get confLow;

  /// No description provided for @currentTarget.
  ///
  /// In ko, this message translates to:
  /// **'현재 목표'**
  String get currentTarget;

  /// No description provided for @newTarget.
  ///
  /// In ko, this message translates to:
  /// **'새 목표 제안'**
  String get newTarget;

  /// No description provided for @noChange.
  ///
  /// In ko, this message translates to:
  /// **'변경 없음'**
  String get noChange;

  /// No description provided for @reasonLowConfidence.
  ///
  /// In ko, this message translates to:
  /// **'이번 주는 기록이 조금 부족해요 (식사 {logged}/7일, 체중 {weighs}회). 목표는 그대로 둘게요. 식사 5일, 체중 3회 이상이면 조정할 수 있어요.'**
  String reasonLowConfidence(String logged, String weighs);

  /// No description provided for @reasonPlateau.
  ///
  /// In ko, this message translates to:
  /// **'체중 추세가 2주째 거의 그대로예요. 계산해 보니 소비량이 약 {tdee} kcal로 낮아진 것 같아요. 목표를 살짝 낮춰볼까요?'**
  String reasonPlateau(String tdee);

  /// No description provided for @reasonTdeeUp.
  ///
  /// In ko, this message translates to:
  /// **'생각보다 에너지를 더 쓰고 있어요! 추정 소비량을 {tdee} kcal로 올렸어요.'**
  String reasonTdeeUp(String tdee);

  /// No description provided for @reasonTdeeDown.
  ///
  /// In ko, this message translates to:
  /// **'추정 소비량이 {tdee} kcal로 조금 내려갔어요. 목표를 그에 맞게 조정할게요.'**
  String reasonTdeeDown(String tdee);

  /// No description provided for @reasonOnTrack.
  ///
  /// In ko, this message translates to:
  /// **'계획대로 잘 가고 있어요! 목표는 거의 그대로예요.'**
  String get reasonOnTrack;

  /// No description provided for @floorHitCheckin.
  ///
  /// In ko, this message translates to:
  /// **'안전 하한 때문에 {kcal} kcal 아래로는 내리지 않았어요. 속도를 낮추는 걸 고려해 보세요.'**
  String floorHitCheckin(String kcal);

  /// No description provided for @accept.
  ///
  /// In ko, this message translates to:
  /// **'수락'**
  String get accept;

  /// No description provided for @keep.
  ///
  /// In ko, this message translates to:
  /// **'유지'**
  String get keep;

  /// No description provided for @adjust.
  ///
  /// In ko, this message translates to:
  /// **'직접 조정'**
  String get adjust;

  /// No description provided for @manualKcalTitle.
  ///
  /// In ko, this message translates to:
  /// **'목표 칼로리 직접 입력'**
  String get manualKcalTitle;

  /// No description provided for @manualKcalFloor.
  ///
  /// In ko, this message translates to:
  /// **'최소 {kcal} kcal 이상이어야 해요'**
  String manualKcalFloor(String kcal);

  /// No description provided for @appliedAccept.
  ///
  /// In ko, this message translates to:
  /// **'새 목표를 적용했어요!'**
  String get appliedAccept;

  /// No description provided for @appliedKeep.
  ///
  /// In ko, this message translates to:
  /// **'기존 목표를 유지해요'**
  String get appliedKeep;

  /// No description provided for @appliedManual.
  ///
  /// In ko, this message translates to:
  /// **'직접 정한 목표를 적용했어요'**
  String get appliedManual;

  /// No description provided for @howCalculated.
  ///
  /// In ko, this message translates to:
  /// **'어떻게 계산했나요?'**
  String get howCalculated;

  /// No description provided for @howCalculatedBody.
  ///
  /// In ko, this message translates to:
  /// **'최근 {window}일 동안 평균 {intake} kcal를 먹었고 추세 체중이 {delta}kg 변했어요. 1kg을 약 7,700 kcal로 환산하면 실제 소비량은 약 {obs} kcal예요. 이를 공식 추정치({formula} kcal)와 섞고, 한 주 변화폭을 ±150 kcal로 제한해서 {est} kcal로 정했어요.'**
  String howCalculatedBody(
    String window,
    String intake,
    String delta,
    String obs,
    String formula,
    String est,
  );

  /// No description provided for @noObservedYet.
  ///
  /// In ko, this message translates to:
  /// **'아직 실측 데이터가 부족해서 공식 추정치({formula} kcal)를 기준으로 해요. 2주 정도 꾸준히 기록하면 실제 소비량을 계산할 수 있어요.'**
  String noObservedYet(String formula);

  /// No description provided for @planHistory.
  ///
  /// In ko, this message translates to:
  /// **'목표 변화 기록'**
  String get planHistory;

  /// No description provided for @statusInitial.
  ///
  /// In ko, this message translates to:
  /// **'시작'**
  String get statusInitial;

  /// No description provided for @statusAccepted.
  ///
  /// In ko, this message translates to:
  /// **'수락'**
  String get statusAccepted;

  /// No description provided for @statusKept.
  ///
  /// In ko, this message translates to:
  /// **'유지'**
  String get statusKept;

  /// No description provided for @statusManual.
  ///
  /// In ko, this message translates to:
  /// **'직접'**
  String get statusManual;

  /// No description provided for @checkinDone.
  ///
  /// In ko, this message translates to:
  /// **'이번 주 체크인 완료!'**
  String get checkinDone;

  /// No description provided for @checkinDoneDesc.
  ///
  /// In ko, this message translates to:
  /// **'다음 체크인까지 꾸준히 기록해 주세요. 기록이 많을수록 정확해져요.'**
  String get checkinDoneDesc;

  /// No description provided for @checkinAnyway.
  ///
  /// In ko, this message translates to:
  /// **'그래도 지금 다시 계산해 보기'**
  String get checkinAnyway;

  /// No description provided for @backToToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘로'**
  String get backToToday;

  /// No description provided for @usageAnalytics.
  ///
  /// In ko, this message translates to:
  /// **'사용 데이터 보내기'**
  String get usageAnalytics;

  /// No description provided for @usageAnalyticsDesc.
  ///
  /// In ko, this message translates to:
  /// **'어떤 기능을 쓰는지만 익명으로 보내 앱 개선에 써요. 체중·식사 같은 건강 정보는 보내지 않아요.'**
  String get usageAnalyticsDesc;

  /// No description provided for @privacyPolicy.
  ///
  /// In ko, this message translates to:
  /// **'개인정보처리방침'**
  String get privacyPolicy;

  /// No description provided for @signInNotice.
  ///
  /// In ko, this message translates to:
  /// **'로그인하면 체중·식사 같은 건강 정보가 기기 간 동기화를 위해 서버에 저장돼요. 계정을 삭제하면 바로 지워져요.'**
  String get signInNotice;

  /// No description provided for @sectionAccount.
  ///
  /// In ko, this message translates to:
  /// **'계정'**
  String get sectionAccount;

  /// No description provided for @signInTitle.
  ///
  /// In ko, this message translates to:
  /// **'로그인하고 기록 지키기'**
  String get signInTitle;

  /// No description provided for @signInBody.
  ///
  /// In ko, this message translates to:
  /// **'로그인하면 기록이 계정에 저장돼서 폰을 바꾸거나 여러 기기에서 써도 그대로 이어져요.'**
  String get signInBody;

  /// No description provided for @signInCta.
  ///
  /// In ko, this message translates to:
  /// **'로그인하고 동기화'**
  String get signInCta;

  /// No description provided for @signInApple.
  ///
  /// In ko, this message translates to:
  /// **'Apple로 계속하기'**
  String get signInApple;

  /// No description provided for @signInGoogle.
  ///
  /// In ko, this message translates to:
  /// **'Google로 계속하기'**
  String get signInGoogle;

  /// No description provided for @signInKakao.
  ///
  /// In ko, this message translates to:
  /// **'카카오로 계속하기'**
  String get signInKakao;

  /// No description provided for @signInFailed.
  ///
  /// In ko, this message translates to:
  /// **'로그인하지 못했어요. 다시 시도해 주세요.'**
  String get signInFailed;

  /// No description provided for @signInUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'이 빌드에서는 로그인을 쓸 수 없어요.'**
  String get signInUnavailable;

  /// No description provided for @haveAccount.
  ///
  /// In ko, this message translates to:
  /// **'이미 계정이 있어요 · 로그인해서 불러오기'**
  String get haveAccount;

  /// No description provided for @restoringData.
  ///
  /// In ko, this message translates to:
  /// **'저장된 기록을 불러오는 중…'**
  String get restoringData;

  /// No description provided for @noSavedDataTitle.
  ///
  /// In ko, this message translates to:
  /// **'이 계정에 저장된 기록이 없어요'**
  String get noSavedDataTitle;

  /// No description provided for @noSavedDataBody.
  ///
  /// In ko, this message translates to:
  /// **'목표와 키·몸무게를 입력하면 이 계정에 저장되고, 다른 기기에서도 불러올 수 있어요.'**
  String get noSavedDataBody;

  /// No description provided for @agreeAndStart.
  ///
  /// In ko, this message translates to:
  /// **'동의하고 입력하기'**
  String get agreeAndStart;

  /// No description provided for @restoreFailed.
  ///
  /// In ko, this message translates to:
  /// **'기록을 불러오지 못했어요. 인터넷 연결을 확인하고 다시 시도해 주세요.'**
  String get restoreFailed;

  /// No description provided for @syncing.
  ///
  /// In ko, this message translates to:
  /// **'동기화 중…'**
  String get syncing;

  /// No description provided for @syncedAt.
  ///
  /// In ko, this message translates to:
  /// **'{time}에 동기화됨'**
  String syncedAt(String time);

  /// No description provided for @syncFailed.
  ///
  /// In ko, this message translates to:
  /// **'동기화하지 못했어요. 연결되면 다시 시도할게요.'**
  String get syncFailed;

  /// No description provided for @syncNow.
  ///
  /// In ko, this message translates to:
  /// **'지금 동기화'**
  String get syncNow;

  /// No description provided for @signOut.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get signOut;

  /// No description provided for @signOutConfirm.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃하면 이 기기의 기록은 지워져요. 계정에는 그대로 있어서 다시 로그인하면 불러와요.'**
  String get signOutConfirm;

  /// No description provided for @deleteAccount.
  ///
  /// In ko, this message translates to:
  /// **'계정 삭제'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In ko, this message translates to:
  /// **'계정과 모든 기록을 영구적으로 삭제할까요? 되돌릴 수 없어요.'**
  String get deleteAccountConfirm;

  /// No description provided for @streakTitle.
  ///
  /// In ko, this message translates to:
  /// **'연속 {days}일째 기록 중!'**
  String streakTitle(String days);

  /// No description provided for @streakZero.
  ///
  /// In ko, this message translates to:
  /// **'오늘 첫 기록으로 연속 기록을 시작해요'**
  String get streakZero;

  /// No description provided for @pickDate.
  ///
  /// In ko, this message translates to:
  /// **'날짜 선택'**
  String get pickDate;

  /// No description provided for @logCalendarTitle.
  ///
  /// In ko, this message translates to:
  /// **'기록 달력'**
  String get logCalendarTitle;

  /// No description provided for @logCalendarDays.
  ///
  /// In ko, this message translates to:
  /// **'{logged}/{total}일 기록'**
  String logCalendarDays(String logged, String total);

  /// No description provided for @logCurrentStreak.
  ///
  /// In ko, this message translates to:
  /// **'지금 {days}일 연속'**
  String logCurrentStreak(String days);

  /// No description provided for @logLongestStreak.
  ///
  /// In ko, this message translates to:
  /// **'최장 {days}일 연속'**
  String logLongestStreak(String days);

  /// No description provided for @logMissedDays.
  ///
  /// In ko, this message translates to:
  /// **'놓친 날 {days}일'**
  String logMissedDays(String days);

  /// No description provided for @logLegendDone.
  ///
  /// In ko, this message translates to:
  /// **'기록함'**
  String get logLegendDone;

  /// No description provided for @logLegendMissed.
  ///
  /// In ko, this message translates to:
  /// **'놓침'**
  String get logLegendMissed;

  /// No description provided for @logLegendToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get logLegendToday;

  /// No description provided for @logCalendarHint.
  ///
  /// In ko, this message translates to:
  /// **'식사·체중·운동 중 하나라도 기록한 날은 체크, 기록이 없던 날은 X로 표시돼요. 날짜를 누르면 그날로 이동해요.'**
  String get logCalendarHint;

  /// No description provided for @weekMeals.
  ///
  /// In ko, this message translates to:
  /// **'식사 {n}/7일'**
  String weekMeals(String n);

  /// No description provided for @weekWeighs.
  ///
  /// In ko, this message translates to:
  /// **'체중 {n}회'**
  String weekWeighs(String n);

  /// No description provided for @weekLogHint.
  ///
  /// In ko, this message translates to:
  /// **'식사 5일 · 체중 3회 이상 기록하면 체크인에서 목표를 조정할 수 있어요'**
  String get weekLogHint;

  /// No description provided for @weekLogReady.
  ///
  /// In ko, this message translates to:
  /// **'이번 주 기록이 충분해요. 체크인 때 정확하게 조정할 수 있어요!'**
  String get weekLogReady;

  /// No description provided for @editMeal.
  ///
  /// In ko, this message translates to:
  /// **'식사 수정'**
  String get editMeal;

  /// No description provided for @mealUpdated.
  ///
  /// In ko, this message translates to:
  /// **'수정했어요'**
  String get mealUpdated;

  /// No description provided for @searchAgain.
  ///
  /// In ko, this message translates to:
  /// **'다시 검색'**
  String get searchAgain;

  /// No description provided for @updateAvailable.
  ///
  /// In ko, this message translates to:
  /// **'새 버전이 나왔어요'**
  String get updateAvailable;

  /// No description provided for @reload.
  ///
  /// In ko, this message translates to:
  /// **'새로고침'**
  String get reload;

  /// No description provided for @updateInStore.
  ///
  /// In ko, this message translates to:
  /// **'새 버전이 나왔어요. 스토어에서 업데이트해 주세요'**
  String get updateInStore;

  /// No description provided for @updateStoreAction.
  ///
  /// In ko, this message translates to:
  /// **'업데이트'**
  String get updateStoreAction;

  /// No description provided for @pressBackAgainToExit.
  ///
  /// In ko, this message translates to:
  /// **'한 번 더 누르면 앱이 닫혀요'**
  String get pressBackAgainToExit;

  /// No description provided for @replaceMeal.
  ///
  /// In ko, this message translates to:
  /// **'다른 음식으로 바꾸기'**
  String get replaceMeal;

  /// No description provided for @mealReplaced.
  ///
  /// In ko, this message translates to:
  /// **'{name} 바꿨어요'**
  String mealReplaced(String name);

  /// No description provided for @recentMeals.
  ///
  /// In ko, this message translates to:
  /// **'최근 먹은 것'**
  String get recentMeals;

  /// No description provided for @savedMealsTitle.
  ///
  /// In ko, this message translates to:
  /// **'내 식사'**
  String get savedMealsTitle;

  /// No description provided for @mealsOnDay.
  ///
  /// In ko, this message translates to:
  /// **'이날 먹은 것'**
  String get mealsOnDay;

  /// No description provided for @weightOnDay.
  ///
  /// In ko, this message translates to:
  /// **'이날 체중'**
  String get weightOnDay;

  /// No description provided for @noMealsPast.
  ///
  /// In ko, this message translates to:
  /// **'이날은 기록이 없어요.\n아래 버튼으로 빠진 식사를 채울 수 있어요.'**
  String get noMealsPast;

  /// No description provided for @pastDayGreeting.
  ///
  /// In ko, this message translates to:
  /// **'지난 기록 채우기'**
  String get pastDayGreeting;

  /// No description provided for @workoutsTitle.
  ///
  /// In ko, this message translates to:
  /// **'운동'**
  String get workoutsTitle;

  /// No description provided for @workoutsOnDay.
  ///
  /// In ko, this message translates to:
  /// **'이날 운동'**
  String get workoutsOnDay;

  /// No description provided for @logWorkout.
  ///
  /// In ko, this message translates to:
  /// **'운동 기록'**
  String get logWorkout;

  /// No description provided for @noWorkouts.
  ///
  /// In ko, this message translates to:
  /// **'아직 운동 기록이 없어요'**
  String get noWorkouts;

  /// No description provided for @minutesN.
  ///
  /// In ko, this message translates to:
  /// **'{n}분'**
  String minutesN(String n);

  /// No description provided for @workoutMinutes.
  ///
  /// In ko, this message translates to:
  /// **'운동 시간'**
  String get workoutMinutes;

  /// No description provided for @workoutAdded.
  ///
  /// In ko, this message translates to:
  /// **'{type} {minutes}분 기록!'**
  String workoutAdded(String type, String minutes);

  /// No description provided for @workoutDeleted.
  ///
  /// In ko, this message translates to:
  /// **'운동 기록을 지웠어요'**
  String get workoutDeleted;

  /// No description provided for @workoutNoCalories.
  ///
  /// In ko, this message translates to:
  /// **'운동 칼로리는 목표에 더하지 않아요. 운동으로 쓴 에너지는 체중 변화에 이미 반영되어 매주 소비량 계산에 들어가요.'**
  String get workoutNoCalories;

  /// No description provided for @weekWorkouts.
  ///
  /// In ko, this message translates to:
  /// **'운동 {n}회'**
  String weekWorkouts(String n);

  /// No description provided for @workoutSuggestTitle.
  ///
  /// In ko, this message translates to:
  /// **'운동 횟수를 맞춰볼까요?'**
  String get workoutSuggestTitle;

  /// No description provided for @workoutSuggestBody.
  ///
  /// In ko, this message translates to:
  /// **'지난 2주 동안 주 평균 근력 {strength}회 · 유산소 {cardio}회 운동했어요. 설정은 주 {planned}회예요. 실제 기록에 맞추면 공식 추정치가 더 정확해져요.'**
  String workoutSuggestBody(String strength, String cardio, String planned);

  /// No description provided for @workoutSuggestApply.
  ///
  /// In ko, this message translates to:
  /// **'기록에 맞추기'**
  String get workoutSuggestApply;

  /// No description provided for @workoutSuggestApplied.
  ///
  /// In ko, this message translates to:
  /// **'운동 횟수를 업데이트했어요'**
  String get workoutSuggestApplied;

  /// No description provided for @workoutTrendTitle.
  ///
  /// In ko, this message translates to:
  /// **'운동 추이'**
  String get workoutTrendTitle;

  /// No description provided for @statusDietBreak.
  ///
  /// In ko, this message translates to:
  /// **'쉬어가기'**
  String get statusDietBreak;

  /// No description provided for @stallTitle.
  ///
  /// In ko, this message translates to:
  /// **'체중이 3주째 거의 그대로예요'**
  String get stallTitle;

  /// No description provided for @stallBody.
  ///
  /// In ko, this message translates to:
  /// **'정체기는 누구에게나 와요. 세 가지 중 하나를 골라 보세요.'**
  String get stallBody;

  /// No description provided for @stallCheckLogs.
  ///
  /// In ko, this message translates to:
  /// **'① 기록 점검하기'**
  String get stallCheckLogs;

  /// No description provided for @stallCheckLogsBody.
  ///
  /// In ko, this message translates to:
  /// **'소스·음료·간식이 빠지면 실제보다 적게 먹은 걸로 계산돼요. 목표의 60%도 안 되는 날:'**
  String get stallCheckLogsBody;

  /// No description provided for @stallNoSuspicious.
  ///
  /// In ko, this message translates to:
  /// **'최근 2주에 의심되는 날은 없어요. 기록은 잘 되고 있어요.'**
  String get stallNoSuspicious;

  /// No description provided for @stallLower.
  ///
  /// In ko, this message translates to:
  /// **'② 목표를 {kcal} kcal로 낮추기'**
  String stallLower(String kcal);

  /// No description provided for @stallBreak.
  ///
  /// In ko, this message translates to:
  /// **'③ 1~2주 쉬어가기 (유지 칼로리 {kcal} kcal)'**
  String stallBreak(String kcal);

  /// No description provided for @stallBreakBody.
  ///
  /// In ko, this message translates to:
  /// **'잠깐 유지 칼로리로 먹으면 몸과 마음이 회복돼서, 다시 시작할 때 더 잘 빠지는 경우가 많아요. 끝나면 원래 계획으로 돌아가요.'**
  String get stallBreakBody;

  /// No description provided for @breakWeeks.
  ///
  /// In ko, this message translates to:
  /// **'{n}주 쉬기'**
  String breakWeeks(String n);

  /// No description provided for @breakActive.
  ///
  /// In ko, this message translates to:
  /// **'쉬어가는 중 · {date}까지 유지 칼로리로 드세요'**
  String breakActive(String date);

  /// No description provided for @breakStarted.
  ///
  /// In ko, this message translates to:
  /// **'{date}까지 쉬어가요. 체크인은 그다음에 해요.'**
  String breakStarted(String date);

  /// No description provided for @goalReachedTitle.
  ///
  /// In ko, this message translates to:
  /// **'목표 체중에 도달했어요! 🎉'**
  String get goalReachedTitle;

  /// No description provided for @goalReachedBody.
  ///
  /// In ko, this message translates to:
  /// **'정말 수고 많으셨어요. 이제 이 체중을 지키는 유지 모드로 바꿔 볼까요? 목표 칼로리를 소비량에 맞춰 드릴게요.'**
  String get goalReachedBody;

  /// No description provided for @goalReachedMaintain.
  ///
  /// In ko, this message translates to:
  /// **'유지 모드로 바꾸기'**
  String get goalReachedMaintain;

  /// No description provided for @goalReachedLater.
  ///
  /// In ko, this message translates to:
  /// **'나중에'**
  String get goalReachedLater;

  /// No description provided for @maintainStarted.
  ///
  /// In ko, this message translates to:
  /// **'유지 모드로 바꿨어요. 목표는 {kcal} kcal예요.'**
  String maintainStarted(String kcal);

  /// No description provided for @notifDay1Title.
  ///
  /// In ko, this message translates to:
  /// **'오늘 기록 잊지 않으셨죠?'**
  String get notifDay1Title;

  /// No description provided for @notifDay1Body.
  ///
  /// In ko, this message translates to:
  /// **'대충이라도 괜찮아요. 한 끼만 넣어도 추정이 정확해져요.'**
  String get notifDay1Body;

  /// No description provided for @notifDay3Title.
  ///
  /// In ko, this message translates to:
  /// **'3일 쉬셨네요'**
  String get notifDay3Title;

  /// No description provided for @notifDay3Body.
  ///
  /// In ko, this message translates to:
  /// **'오늘 한 끼만 기록해도 추세가 다시 이어져요.'**
  String get notifDay3Body;

  /// No description provided for @notifDay7Title.
  ///
  /// In ko, this message translates to:
  /// **'일주일 만이에요'**
  String get notifDay7Title;

  /// No description provided for @notifDay7Body.
  ///
  /// In ko, this message translates to:
  /// **'체중만 재도 코칭이 다시 시작돼요.'**
  String get notifDay7Body;

  /// No description provided for @notifDay14Title.
  ///
  /// In ko, this message translates to:
  /// **'다시 시작해 볼까요?'**
  String get notifDay14Title;

  /// No description provided for @notifDay14Body.
  ///
  /// In ko, this message translates to:
  /// **'목표 칼로리를 지금 몸에 맞게 다시 맞춰 드릴게요.'**
  String get notifDay14Body;

  /// No description provided for @notifDay21Title.
  ///
  /// In ko, this message translates to:
  /// **'3주째 쉬고 계시네요'**
  String get notifDay21Title;

  /// No description provided for @notifDay21Body.
  ///
  /// In ko, this message translates to:
  /// **'완벽하지 않아도 돼요. 오늘 한 끼부터 다시 시작해 봐요.'**
  String get notifDay21Body;

  /// No description provided for @notifDay28Title.
  ///
  /// In ko, this message translates to:
  /// **'한 달이 됐어요'**
  String get notifDay28Title;

  /// No description provided for @notifDay28Body.
  ///
  /// In ko, this message translates to:
  /// **'지금 체중 한 번만 재 주시면, 거기서부터 다시 맞춰 드릴게요.'**
  String get notifDay28Body;

  /// No description provided for @notifLong1Title.
  ///
  /// In ko, this message translates to:
  /// **'알아서핏이 기다리고 있어요'**
  String get notifLong1Title;

  /// No description provided for @notifLong1Body.
  ///
  /// In ko, this message translates to:
  /// **'언제든 돌아오시면 거기서부터 다시 맞춰 드려요.'**
  String get notifLong1Body;

  /// No description provided for @notifLong2Title.
  ///
  /// In ko, this message translates to:
  /// **'체중만 재 볼까요?'**
  String get notifLong2Title;

  /// No description provided for @notifLong2Body.
  ///
  /// In ko, this message translates to:
  /// **'기록 없이 체중만 넣어도 추세를 다시 이어 갈 수 있어요.'**
  String get notifLong2Body;

  /// No description provided for @notifLong3Title.
  ///
  /// In ko, this message translates to:
  /// **'새로 시작하기 좋은 날이에요'**
  String get notifLong3Title;

  /// No description provided for @notifLong3Body.
  ///
  /// In ko, this message translates to:
  /// **'목표를 지금 모습에 맞게 다시 세워 드릴게요.'**
  String get notifLong3Body;

  /// No description provided for @notifCheckinTitle.
  ///
  /// In ko, this message translates to:
  /// **'오늘은 체크인 날이에요'**
  String get notifCheckinTitle;

  /// No description provided for @notifCheckinBody.
  ///
  /// In ko, this message translates to:
  /// **'지난주 기록으로 이번 주 목표를 맞춰 드릴게요.'**
  String get notifCheckinBody;

  /// No description provided for @remindersOffer.
  ///
  /// In ko, this message translates to:
  /// **'기록을 쉬면 살짝 알려 드릴까요? 첫 한 달은 일주일에 한 번, 그 뒤로는 2주에 한 번이에요. 설정에서 언제든 끌 수 있어요.'**
  String get remindersOffer;

  /// No description provided for @remindersYes.
  ///
  /// In ko, this message translates to:
  /// **'알려 주세요'**
  String get remindersYes;

  /// No description provided for @remindersNo.
  ///
  /// In ko, this message translates to:
  /// **'괜찮아요'**
  String get remindersNo;

  /// No description provided for @remindersTitle.
  ///
  /// In ko, this message translates to:
  /// **'기록·체크인 알림'**
  String get remindersTitle;

  /// No description provided for @remindersDesc.
  ///
  /// In ko, this message translates to:
  /// **'기록을 쉬면 1·3일째, 첫 한 달은 매주, 그 뒤로는 2주마다, 체크인 날에도 저녁 8시에 알려 드려요'**
  String get remindersDesc;

  /// No description provided for @remindersOnMsg.
  ///
  /// In ko, this message translates to:
  /// **'알림을 켰어요'**
  String get remindersOnMsg;

  /// No description provided for @remindersDenied.
  ///
  /// In ko, this message translates to:
  /// **'알림이 꺼져 있어요. 휴대폰 설정 → 애플리케이션 → 알아서핏 → 알림을 켠 뒤 다시 켜 주세요'**
  String get remindersDenied;

  /// No description provided for @remindersUnsupported.
  ///
  /// In ko, this message translates to:
  /// **'알림은 앱에서 받을 수 있어요'**
  String get remindersUnsupported;

  /// No description provided for @reviewTitle.
  ///
  /// In ko, this message translates to:
  /// **'알아서핏 어떠세요?'**
  String get reviewTitle;

  /// No description provided for @reviewGood.
  ///
  /// In ko, this message translates to:
  /// **'좋아요'**
  String get reviewGood;

  /// No description provided for @reviewBad.
  ///
  /// In ko, this message translates to:
  /// **'아쉬워요'**
  String get reviewBad;

  /// No description provided for @reviewThanks.
  ///
  /// In ko, this message translates to:
  /// **'고마워요! 큰 힘이 돼요'**
  String get reviewThanks;

  /// No description provided for @reviewAskStore.
  ///
  /// In ko, this message translates to:
  /// **'스토어에 별점을 남겨 주시면 더 많은 분이 알아서핏을 만날 수 있어요.'**
  String get reviewAskStore;

  /// No description provided for @reviewRate.
  ///
  /// In ko, this message translates to:
  /// **'별점 남기기'**
  String get reviewRate;

  /// No description provided for @reviewLater.
  ///
  /// In ko, this message translates to:
  /// **'다음에'**
  String get reviewLater;

  /// No description provided for @reviewBadTitle.
  ///
  /// In ko, this message translates to:
  /// **'무엇이 아쉬웠나요?'**
  String get reviewBadTitle;

  /// No description provided for @reviewBadHint.
  ///
  /// In ko, this message translates to:
  /// **'불편했던 점을 알려 주시면 고쳐 볼게요'**
  String get reviewBadHint;

  /// No description provided for @reviewSend.
  ///
  /// In ko, this message translates to:
  /// **'보내기'**
  String get reviewSend;

  /// No description provided for @reviewSent.
  ///
  /// In ko, this message translates to:
  /// **'의견 고마워요. 꼭 참고할게요'**
  String get reviewSent;

  /// No description provided for @reportTitle.
  ///
  /// In ko, this message translates to:
  /// **'이번 주 코칭 리포트'**
  String get reportTitle;

  /// No description provided for @reportAte.
  ///
  /// In ko, this message translates to:
  /// **'먹은 양'**
  String get reportAte;

  /// No description provided for @reportAteValue.
  ///
  /// In ko, this message translates to:
  /// **'최근 {days}일 평균 {kcal} kcal'**
  String reportAteValue(String days, String kcal);

  /// No description provided for @reportTrend.
  ///
  /// In ko, this message translates to:
  /// **'체중 추세'**
  String get reportTrend;

  /// No description provided for @reportTrendValue.
  ///
  /// In ko, this message translates to:
  /// **'{delta}kg → 하루 {bal} kcal {dir}'**
  String reportTrendValue(String delta, String bal, String dir);

  /// No description provided for @reportDeficit.
  ///
  /// In ko, this message translates to:
  /// **'부족'**
  String get reportDeficit;

  /// No description provided for @reportSurplus.
  ///
  /// In ko, this message translates to:
  /// **'남음'**
  String get reportSurplus;

  /// No description provided for @reportObserved.
  ///
  /// In ko, this message translates to:
  /// **'실제 소비량'**
  String get reportObserved;

  /// No description provided for @reportObservedValue.
  ///
  /// In ko, this message translates to:
  /// **'{intake} {sign} {bal} = 약 {obs} kcal'**
  String reportObservedValue(
    String intake,
    String sign,
    String bal,
    String obs,
  );

  /// No description provided for @reportEstimate.
  ///
  /// In ko, this message translates to:
  /// **'추정 소비량'**
  String get reportEstimate;

  /// No description provided for @reportEstimateValue.
  ///
  /// In ko, this message translates to:
  /// **'공식 추정 {formula}와 섞고, 한 주 변화는 ±150 kcal까지만: {prev} → {est} kcal'**
  String reportEstimateValue(String formula, String prev, String est);

  /// No description provided for @reportTarget.
  ///
  /// In ko, this message translates to:
  /// **'새 목표'**
  String get reportTarget;

  /// No description provided for @reportTargetValue.
  ///
  /// In ko, this message translates to:
  /// **'소비량 {est} - {gap} = {target} kcal (주 {kg}kg 페이스)'**
  String reportTargetValue(String est, String gap, String target, String kg);

  /// No description provided for @reportTargetSurplus.
  ///
  /// In ko, this message translates to:
  /// **'소비량 {est} + {gap} = {target} kcal (주 {kg}kg 페이스)'**
  String reportTargetSurplus(String est, String gap, String target, String kg);

  /// No description provided for @reportNoObserved.
  ///
  /// In ko, this message translates to:
  /// **'아직 기록이 2주가 안 돼서 공식으로 소비량을 {formula} kcal로 추정했어요. 기록이 쌓이면 실제 데이터로 바뀌어요.'**
  String reportNoObserved(String formula);

  /// No description provided for @bigEntryTitle.
  ///
  /// In ko, this message translates to:
  /// **'{kcal} kcal이 맞나요?'**
  String bigEntryTitle(String kcal);

  /// No description provided for @bigEntryBody.
  ///
  /// In ko, this message translates to:
  /// **'한 번에 기록하기엔 아주 많은 양이에요. 숫자를 한 자리 더 누르지 않았는지 확인해 주세요.'**
  String get bigEntryBody;

  /// No description provided for @bigEntryFix.
  ///
  /// In ko, this message translates to:
  /// **'고치기'**
  String get bigEntryFix;

  /// No description provided for @bigEntryOk.
  ///
  /// In ko, this message translates to:
  /// **'맞아요'**
  String get bigEntryOk;

  /// No description provided for @numberRange.
  ///
  /// In ko, this message translates to:
  /// **'{min}~{max} 사이'**
  String numberRange(String min, String max);

  /// No description provided for @reportComp.
  ///
  /// In ko, this message translates to:
  /// **'체성분 반영'**
  String get reportComp;

  /// No description provided for @reportCompValue.
  ///
  /// In ko, this message translates to:
  /// **'지방 {fat}kg · 제지방 {lean}kg (최근 {weeks}주) → 1kg당 {kcal} kcal로 계산'**
  String reportCompValue(String fat, String lean, String weeks, String kcal);

  /// No description provided for @reportCompSmall.
  ///
  /// In ko, this message translates to:
  /// **'지방 {fat}kg · 제지방 {lean}kg (최근 {weeks}주) · 변화가 작아 1kg당 {kcal} kcal 그대로'**
  String reportCompSmall(String fat, String lean, String weeks, String kcal);

  /// No description provided for @reportBurn.
  ///
  /// In ko, this message translates to:
  /// **'소비량 구성'**
  String get reportBurn;

  /// No description provided for @reportBurnValue.
  ///
  /// In ko, this message translates to:
  /// **'{bmrLabel} {bmr} · 활동 {activity} · 소화 {digestion} kcal'**
  String reportBurnValue(
    String bmrLabel,
    String bmr,
    String activity,
    String digestion,
  );

  /// No description provided for @burnBmr.
  ///
  /// In ko, this message translates to:
  /// **'기초대사'**
  String get burnBmr;

  /// No description provided for @burnBmrLean.
  ///
  /// In ko, this message translates to:
  /// **'기초대사(제지방 기준)'**
  String get burnBmrLean;

  /// No description provided for @reportCompAdvice.
  ///
  /// In ko, this message translates to:
  /// **'체성분 코칭'**
  String get reportCompAdvice;

  /// No description provided for @compLeanLoss.
  ///
  /// In ko, this message translates to:
  /// **'최근 빠진 체중의 {pct}%가 제지방(근육·수분)이에요. 근육을 지키도록 감량 속도를 30% 늦추고 단백질을 늘렸어요.'**
  String compLeanLoss(String pct);

  /// No description provided for @compFatGain.
  ///
  /// In ko, this message translates to:
  /// **'최근 늘어난 체중의 {pct}%가 지방이에요. 증량 속도를 30% 늦췄어요.'**
  String compFatGain(String pct);

  /// No description provided for @compRecomp.
  ///
  /// In ko, this message translates to:
  /// **'지방 {fat}kg, 제지방 {lean}kg — 체성분 개선이 잘 되고 있어요!'**
  String compRecomp(String fat, String lean);

  /// No description provided for @infoChart.
  ///
  /// In ko, this message translates to:
  /// **'점은 그날 잰 체중, 선은 수분·음식 때문에 출렁이는 값을 걸러 낸 추세예요. 초록 점선은 목표 체중이에요. 그래프를 누르면 그날의 체중·섭취·운동을 볼 수 있어요.'**
  String get infoChart;

  /// No description provided for @infoTrend.
  ///
  /// In ko, this message translates to:
  /// **'최근 체중 기록을 부드럽게 이은 값이에요. 하루 체중보다 실제 변화에 가까워서 목표 계산에 이 값을 써요.'**
  String get infoTrend;

  /// No description provided for @infoWeekly.
  ///
  /// In ko, this message translates to:
  /// **'7일 전 추세와 지금 추세의 차이예요. 감량이라면 일주일에 체중의 0.5~1%가 무리 없는 속도예요.'**
  String get infoWeekly;

  /// No description provided for @infoEta.
  ///
  /// In ko, this message translates to:
  /// **'최근 3~4주 추세(없으면 정한 속도)로 계산한 예상 기간이에요. 기록이 쌓일수록 정확해져요.'**
  String get infoEta;

  /// No description provided for @infoIntake.
  ///
  /// In ko, this message translates to:
  /// **'기록한 날의 섭취 칼로리를 목표와 비교해요. 기록하지 않은 날은 평균에서 빠져요. 막대를 누르면 그날 섭취량이 보여요.'**
  String get infoIntake;

  /// No description provided for @infoSwaps.
  ///
  /// In ko, this message translates to:
  /// **'최근 4주에 자주 드신 음식과 같은 종류 중, 칼로리만이 아니라 탄단지 구성·단백질·당류·포화지방까지 비교해서 더 가벼운 음식만 골라요.'**
  String get infoSwaps;

  /// No description provided for @workoutTapHint.
  ///
  /// In ko, this message translates to:
  /// **'막대를 누르면 그 주 운동 기록이 보여요'**
  String get workoutTapHint;

  /// No description provided for @workoutWeekReadout.
  ///
  /// In ko, this message translates to:
  /// **'{date} 주 · 근력 {s}회 · 유산소 {c}회 · {min}분'**
  String workoutWeekReadout(String date, String s, String c, String min);

  /// No description provided for @infoCkIntake.
  ///
  /// In ko, this message translates to:
  /// **'기록한 날들의 하루 평균 섭취 칼로리예요. 기록이 빠진 날은 평균에서 빠지니, 빠짐없이 기록할수록 정확해져요.'**
  String get infoCkIntake;

  /// No description provided for @infoCkTrend.
  ///
  /// In ko, this message translates to:
  /// **'같은 기간 체중 추세가 얼마나 변했는지예요. 하루 체중이 아니라 수분·음식으로 출렁이는 값을 걸러 낸 추세로 계산해요.'**
  String get infoCkTrend;

  /// No description provided for @infoCkTdee.
  ///
  /// In ko, this message translates to:
  /// **'하루에 쓰는 총 칼로리 추정치예요. 처음엔 키·체중·나이 공식으로 시작하고, 실제 섭취와 체중 변화로 매주 보정해요. 한 주에 최대 150 kcal까지만 움직여요.'**
  String get infoCkTdee;

  /// No description provided for @infoCkConfidence.
  ///
  /// In ko, this message translates to:
  /// **'추정을 얼마나 믿을 수 있는지예요. 일주일에 식단 기록 6일·체중 5번 이상이면 높음, 기록 5일·체중 3번 미만이면 낮음이에요. 낮을 때는 목표를 바꾸지 않아요.'**
  String get infoCkConfidence;

  /// No description provided for @infoCkTarget.
  ///
  /// In ko, this message translates to:
  /// **'새 목표는 추정 소비량에서 정한 감량·증량 속도만큼 빼거나 더한 값이에요. 탄단지는 체중과 목표에 맞춰 다시 나눠요.'**
  String get infoCkTarget;

  /// No description provided for @infoCkReport.
  ///
  /// In ko, this message translates to:
  /// **'이번 목표가 어떤 기록과 계산을 거쳐 나왔는지 순서대로 보여 줘요.'**
  String get infoCkReport;

  /// No description provided for @infoCkHistory.
  ///
  /// In ko, this message translates to:
  /// **'지금까지 체크인마다 정한 목표 칼로리와 그때의 소비량 추정이에요.'**
  String get infoCkHistory;

  /// No description provided for @infoWorkout.
  ///
  /// In ko, this message translates to:
  /// **'근력운동·유산소 횟수와 시간이에요. 막대를 누르면 그 주 기록이 보여요. 운동 칼로리는 목표에 따로 더하지 않아요. 쓴 에너지는 체중 변화에 이미 담겨서 매주 소비량 계산에 들어가요.'**
  String get infoWorkout;

  /// No description provided for @infoBodyComp.
  ///
  /// In ko, this message translates to:
  /// **'체지방률·골격근량은 같은 기기, 같은 조건(아침 공복)에서 잰 값끼리 비교해야 정확해요. 2주 이상 간격으로 재면 체크인이 빠진 체중을 지방과 근육으로 나눠서 목표와 단백질을 더 정확히 맞춰요.'**
  String get infoBodyComp;

  /// No description provided for @infoHistory.
  ///
  /// In ko, this message translates to:
  /// **'날짜별로 기록한 체중과 체성분이에요.'**
  String get infoHistory;

  /// No description provided for @compGuideNone.
  ///
  /// In ko, this message translates to:
  /// **'체지방률을 1~2주에 한 번 재서 넣어 주세요. 2주 이상 간격으로 두 번 재면, 체크인이 빠진 체중을 지방과 근육으로 나눠서 섭취 칼로리·단백질·감량 속도를 더 정확하게 맞춰요.'**
  String get compGuideNone;

  /// No description provided for @compGuideWaiting.
  ///
  /// In ko, this message translates to:
  /// **'{date} 이후에 한 번 더 재면 체성분 반영이 시작돼요. (첫 측정과 2주 이상 떨어져야 정확해요)'**
  String compGuideWaiting(String date);

  /// No description provided for @compGuideActive.
  ///
  /// In ko, this message translates to:
  /// **'체성분 반영 중이에요 (최근 8주 {n}번 측정). 1~2주에 한 번씩 계속 재면, 세 번째부터는 측정 오차를 걸러서 더 정확해져요.'**
  String compGuideActive(String n);

  /// No description provided for @swapsTitle.
  ///
  /// In ko, this message translates to:
  /// **'가볍게 바꿔 볼까요?'**
  String get swapsTitle;

  /// No description provided for @swapsDesc.
  ///
  /// In ko, this message translates to:
  /// **'최근 4주에 자주 드신 음식과 같은 종류 중에서, 칼로리만이 아니라 탄단지 구성까지 비슷하고, 단백질은 지키면서 당류·포화지방은 늘지 않는 음식만 골랐어요.'**
  String get swapsDesc;

  /// No description provided for @swapCompare.
  ///
  /// In ko, this message translates to:
  /// **'단백질 {from}→{to}g'**
  String swapCompare(String from, String to);

  /// No description provided for @swapCompareSugar.
  ///
  /// In ko, this message translates to:
  /// **'단백질 {from}→{to}g · 당류 {sFrom}→{sTo}g'**
  String swapCompareSugar(String from, String to, String sFrom, String sTo);

  /// No description provided for @swapTimes.
  ///
  /// In ko, this message translates to:
  /// **'{n}번 드심'**
  String swapTimes(String n);

  /// No description provided for @swapSaves.
  ///
  /// In ko, this message translates to:
  /// **'1회분 {kcal} kcal 적어요'**
  String swapSaves(String kcal);

  /// No description provided for @swapSavesSugar.
  ///
  /// In ko, this message translates to:
  /// **'1회분 {kcal} kcal · 당류 {sugar}g 적어요'**
  String swapSavesSugar(String kcal, String sugar);

  /// No description provided for @patternsTitle.
  ///
  /// In ko, this message translates to:
  /// **'최근 4주 식사 패턴'**
  String get patternsTitle;

  /// No description provided for @patternWeekend.
  ///
  /// In ko, this message translates to:
  /// **'주말에 평일보다 하루 평균 {kcal} kcal 더 드세요. 주말 한 끼만 미리 정해 두면 차이가 확 줄어요.'**
  String patternWeekend(String kcal);

  /// No description provided for @patternSnack.
  ///
  /// In ko, this message translates to:
  /// **'간식이 전체 칼로리의 {pct}%예요. 가장 많이 드신 간식은 \'{food}\'예요. 양을 반으로 줄이거나 단백질 간식으로 바꿔 보세요.'**
  String patternSnack(String pct, String food);

  /// No description provided for @patternSkipBreakfast.
  ///
  /// In ko, this message translates to:
  /// **'아침을 거른 날은 하루에 {kcal} kcal 더 드시는 편이에요. 가벼운 아침(계란·요거트)이 오히려 도움이 될 수 있어요.'**
  String patternSkipBreakfast(String kcal);

  /// No description provided for @focusTitle.
  ///
  /// In ko, this message translates to:
  /// **'다음 주 한 가지'**
  String get focusTitle;

  /// No description provided for @focusLogMore.
  ///
  /// In ko, this message translates to:
  /// **'식사를 5일 이상 기록해 주세요 (이번 주 {n}일). 그래야 소비량을 제대로 계산할 수 있어요.'**
  String focusLogMore(String n);

  /// No description provided for @focusWeighMore.
  ///
  /// In ko, this message translates to:
  /// **'체중을 주 3회 이상 재 주세요 (이번 주 {n}회). 아침 공복에 재면 가장 정확해요.'**
  String focusWeighMore(String n);

  /// No description provided for @focusKeepTarget.
  ///
  /// In ko, this message translates to:
  /// **'평균이 목표보다 {kcal} kcal 많았어요. 목표를 더 낮추기보다 지금 목표를 지키는 게 먼저예요.'**
  String focusKeepTarget(String kcal);

  /// No description provided for @focusMoreProtein.
  ///
  /// In ko, this message translates to:
  /// **'단백질이 하루 평균 {g}g이에요 (목표 {target}g). 끼니마다 단백질 한 가지씩 더해 보세요.'**
  String focusMoreProtein(String g, String target);

  /// No description provided for @focusKeepGoing.
  ///
  /// In ko, this message translates to:
  /// **'기록도 식사도 잘 지키고 있어요. 이번 주도 지금처럼만 하면 돼요!'**
  String get focusKeepGoing;

  /// No description provided for @tipMissedYesterday.
  ///
  /// In ko, this message translates to:
  /// **'어제 식사 기록이 비어 있어요. 기억나는 만큼만 넣어도 소비량 추정이 훨씬 정확해져요.'**
  String get tipMissedYesterday;

  /// No description provided for @tipOverKcal.
  ///
  /// In ko, this message translates to:
  /// **'오늘은 목표보다 {kcal} kcal 더 드셨어요. 괜찮아요, 중요한 건 한 주 평균이에요. 내일 평소대로 드시면 충분해요.'**
  String tipOverKcal(String kcal);

  /// No description provided for @tipOverSugar.
  ///
  /// In ko, this message translates to:
  /// **'당류가 한도보다 {g}g 많아요. 단 음료나 디저트 하나만 바꿔도 금방 줄어요.'**
  String tipOverSugar(String g);

  /// No description provided for @tipOverSatFat.
  ///
  /// In ko, this message translates to:
  /// **'포화지방이 한도보다 {g}g 많아요. 튀김·가공육·크림 대신 구이나 살코기를 골라 보세요.'**
  String tipOverSatFat(String g);

  /// No description provided for @tipProteinLeft.
  ///
  /// In ko, this message translates to:
  /// **'단백질이 {g}g 남았어요. {food} {grams}g이면 대부분 채워져요.'**
  String tipProteinLeft(String g, String food, String grams);

  /// No description provided for @tipProteinLeftPlain.
  ///
  /// In ko, this message translates to:
  /// **'단백질이 {g}g 남았어요. 남은 식사에 고기·생선·두부·계란을 넣어 보세요.'**
  String tipProteinLeftPlain(String g);

  /// No description provided for @tipLowKcalLeft.
  ///
  /// In ko, this message translates to:
  /// **'남은 칼로리가 {kcal} kcal예요. 저녁은 채소와 단백질 위주로 가볍게 드셔 보세요.'**
  String tipLowKcalLeft(String kcal);

  /// No description provided for @tipMorningPlan.
  ///
  /// In ko, this message translates to:
  /// **'오늘 목표는 {kcal} kcal, 단백질 {g}g이에요. 끼니마다 단백질부터 챙겨 보세요.'**
  String tipMorningPlan(String kcal, String g);

  /// No description provided for @tipOnTrack.
  ///
  /// In ko, this message translates to:
  /// **'지금까지 목표 안에서 잘 드시고 있어요. 이대로면 충분해요!'**
  String get tipOnTrack;

  /// No description provided for @intakeTrendTitle.
  ///
  /// In ko, this message translates to:
  /// **'섭취 칼로리'**
  String get intakeTrendTitle;

  /// No description provided for @intakeAvg.
  ///
  /// In ko, this message translates to:
  /// **'평균 섭취'**
  String get intakeAvg;

  /// No description provided for @intakeAvgTarget.
  ///
  /// In ko, this message translates to:
  /// **'평균 목표'**
  String get intakeAvgTarget;

  /// No description provided for @intakeLoggedDays.
  ///
  /// In ko, this message translates to:
  /// **'기록한 날'**
  String get intakeLoggedDays;

  /// No description provided for @intakeLegend.
  ///
  /// In ko, this message translates to:
  /// **'섭취'**
  String get intakeLegend;

  /// No description provided for @intakeTarget.
  ///
  /// In ko, this message translates to:
  /// **'목표'**
  String get intakeTarget;

  /// No description provided for @intakeNotLogged.
  ///
  /// In ko, this message translates to:
  /// **'기록 없음'**
  String get intakeNotLogged;

  /// No description provided for @intakeTapHint.
  ///
  /// In ko, this message translates to:
  /// **'막대를 누르면 그날 섭취량을 볼 수 있어요 (평균은 기록한 날만)'**
  String get intakeTapHint;

  /// No description provided for @workoutThisWeek.
  ///
  /// In ko, this message translates to:
  /// **'최근 7일'**
  String get workoutThisWeek;

  /// No description provided for @workoutThisWeekValue.
  ///
  /// In ko, this message translates to:
  /// **'{n}회 · {minutes}분'**
  String workoutThisWeekValue(String n, String minutes);

  /// No description provided for @workoutAvg4w.
  ///
  /// In ko, this message translates to:
  /// **'4주 평균'**
  String get workoutAvg4w;

  /// No description provided for @workoutAvgValue.
  ///
  /// In ko, this message translates to:
  /// **'주 {n}회'**
  String workoutAvgValue(String n);

  /// No description provided for @legendPlanned.
  ///
  /// In ko, this message translates to:
  /// **'설정 횟수'**
  String get legendPlanned;

  /// No description provided for @noWorkoutData.
  ///
  /// In ko, this message translates to:
  /// **'운동을 기록하면 주별 추이를 볼 수 있어요'**
  String get noWorkoutData;

  /// No description provided for @tipRest.
  ///
  /// In ko, this message translates to:
  /// **'{days}일 연속 운동했어요! 회복도 운동의 일부예요. 하루쯤 쉬어도 괜찮아요.'**
  String tipRest(String days);

  /// No description provided for @tipStrengthForLoss.
  ///
  /// In ko, this message translates to:
  /// **'감량 중엔 근력운동을 주 {target}일 이상 하면 근육을 지키는 데 도움이 돼요. (최근 7일 {days}일)'**
  String tipStrengthForLoss(String target, String days);

  /// No description provided for @tipMoreThanUsual.
  ///
  /// In ko, this message translates to:
  /// **'최근 3주 평균보다 {minutes}분 더 운동했어요!'**
  String tipMoreThanUsual(String minutes);

  /// No description provided for @tipLessThanUsual.
  ///
  /// In ko, this message translates to:
  /// **'최근 3주 평균보다 {minutes}분 적어요. 바쁜 한 주였다면 짧게라도 괜찮아요.'**
  String tipLessThanUsual(String minutes);

  /// No description provided for @tipPlanDone.
  ///
  /// In ko, this message translates to:
  /// **'이번 주 목표 {sessions}회를 채웠어요!'**
  String tipPlanDone(String sessions);

  /// No description provided for @tipPlanRemaining.
  ///
  /// In ko, this message translates to:
  /// **'주 {planned}회 목표까지 {left}회 남았어요.'**
  String tipPlanRemaining(String planned, String left);

  /// No description provided for @tipCardioDone.
  ///
  /// In ko, this message translates to:
  /// **'유산소 {minutes}분으로 WHO 권장량(주 150분)을 채웠어요!'**
  String tipCardioDone(String minutes);

  /// No description provided for @tipCardioProgress.
  ///
  /// In ko, this message translates to:
  /// **'유산소 {minutes}분 · WHO 권장량(주 150분)까지 {left}분 남았어요.'**
  String tipCardioProgress(String minutes, String left);

  /// No description provided for @workoutFeedbackTitle.
  ///
  /// In ko, this message translates to:
  /// **'이번 주 운동 피드백'**
  String get workoutFeedbackTitle;

  /// No description provided for @minutesField.
  ///
  /// In ko, this message translates to:
  /// **'분'**
  String get minutesField;

  /// No description provided for @slotBreakfast.
  ///
  /// In ko, this message translates to:
  /// **'아침'**
  String get slotBreakfast;

  /// No description provided for @slotLunch.
  ///
  /// In ko, this message translates to:
  /// **'점심'**
  String get slotLunch;

  /// No description provided for @slotDinner.
  ///
  /// In ko, this message translates to:
  /// **'저녁'**
  String get slotDinner;

  /// No description provided for @slotSnack.
  ///
  /// In ko, this message translates to:
  /// **'간식'**
  String get slotSnack;

  /// No description provided for @tabSearch.
  ///
  /// In ko, this message translates to:
  /// **'검색'**
  String get tabSearch;

  /// No description provided for @searchHint.
  ///
  /// In ko, this message translates to:
  /// **'음식 검색 (예: 닭가슴살, 신라면)'**
  String get searchHint;

  /// No description provided for @recentFoodsChip.
  ///
  /// In ko, this message translates to:
  /// **'최근'**
  String get recentFoodsChip;

  /// No description provided for @addMealToSlot.
  ///
  /// In ko, this message translates to:
  /// **'{slot} 기록'**
  String addMealToSlot(String slot);

  /// No description provided for @recentSearches.
  ///
  /// In ko, this message translates to:
  /// **'최근 검색'**
  String get recentSearches;

  /// No description provided for @clearAll.
  ///
  /// In ko, this message translates to:
  /// **'전체 삭제'**
  String get clearAll;

  /// No description provided for @macroSummary.
  ///
  /// In ko, this message translates to:
  /// **'단백질 {p}g · 탄수화물 {c}g · 지방 {f}g'**
  String macroSummary(String p, String c, String f);

  /// No description provided for @noRecentFoods.
  ///
  /// In ko, this message translates to:
  /// **'검색해서 기록한 음식이 여기에 모여요'**
  String get noRecentFoods;

  /// No description provided for @noResults.
  ///
  /// In ko, this message translates to:
  /// **'\'{query}\' 검색 결과가 없어요'**
  String noResults(String query);

  /// No description provided for @remoteSearching.
  ///
  /// In ko, this message translates to:
  /// **'전체 식품 DB(약 30만 개)에서 더 찾는 중…'**
  String get remoteSearching;

  /// No description provided for @remoteSearchFailed.
  ///
  /// In ko, this message translates to:
  /// **'전체 식품 DB에 연결하지 못했어요. 앱에 있는 음식만 보여요.'**
  String get remoteSearchFailed;

  /// No description provided for @remoteResults.
  ///
  /// In ko, this message translates to:
  /// **'전체 식품 DB에서 {n}개 더'**
  String remoteResults(String n);

  /// No description provided for @createFood.
  ///
  /// In ko, this message translates to:
  /// **'내 음식 만들기'**
  String get createFood;

  /// No description provided for @createFoodDesc.
  ///
  /// In ko, this message translates to:
  /// **'찾는 음식이 없으면 직접 만들어 저장해요'**
  String get createFoodDesc;

  /// No description provided for @foodMacrosEstimatedNote.
  ///
  /// In ko, this message translates to:
  /// **'\'추정\'(~)은 업체가 공개하지 않은 값을 비슷한 음식의 영양정보로 계산한 거예요.'**
  String get foodMacrosEstimatedNote;

  /// No description provided for @estimated.
  ///
  /// In ko, this message translates to:
  /// **'추정'**
  String get estimated;

  /// No description provided for @foodRefNote.
  ///
  /// In ko, this message translates to:
  /// **'영양정보는 일반적인 참고값이에요. 제품·조리법에 따라 다를 수 있어요.'**
  String get foodRefNote;

  /// No description provided for @unitLabel.
  ///
  /// In ko, this message translates to:
  /// **'단위'**
  String get unitLabel;

  /// No description provided for @quantity.
  ///
  /// In ko, this message translates to:
  /// **'수량'**
  String get quantity;

  /// No description provided for @addToSlot.
  ///
  /// In ko, this message translates to:
  /// **'{slot}에 추가'**
  String addToSlot(String slot);

  /// No description provided for @removeFromSlot.
  ///
  /// In ko, this message translates to:
  /// **'{slot}에서 빼기'**
  String removeFromSlot(String slot);

  /// No description provided for @removeShort.
  ///
  /// In ko, this message translates to:
  /// **'빼기'**
  String get removeShort;

  /// No description provided for @pickSlot.
  ///
  /// In ko, this message translates to:
  /// **'어떤 끼니를 기록할까요?'**
  String get pickSlot;

  /// No description provided for @updateInSlot.
  ///
  /// In ko, this message translates to:
  /// **'{slot} 기록 수정하기'**
  String updateInSlot(String slot);

  /// No description provided for @addedCount.
  ///
  /// In ko, this message translates to:
  /// **'{n}개 추가됨'**
  String addedCount(String n);

  /// No description provided for @done.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get done;

  /// No description provided for @foodName.
  ///
  /// In ko, this message translates to:
  /// **'음식 이름'**
  String get foodName;

  /// No description provided for @servingLabel.
  ///
  /// In ko, this message translates to:
  /// **'1회 제공 단위'**
  String get servingLabel;

  /// No description provided for @servingGrams.
  ///
  /// In ko, this message translates to:
  /// **'중량 g (선택)'**
  String get servingGrams;

  /// No description provided for @perServing.
  ///
  /// In ko, this message translates to:
  /// **'1회 제공량 기준 영양정보'**
  String get perServing;

  /// No description provided for @customSaved.
  ///
  /// In ko, this message translates to:
  /// **'{name} 내 음식에 저장했어요'**
  String customSaved(String name);

  /// No description provided for @photoSoonShort.
  ///
  /// In ko, this message translates to:
  /// **'사진 분석은 곧 제공돼요'**
  String get photoSoonShort;

  /// No description provided for @mealSlotLabel.
  ///
  /// In ko, this message translates to:
  /// **'끼니'**
  String get mealSlotLabel;

  /// No description provided for @addedToSlot.
  ///
  /// In ko, this message translates to:
  /// **'{name} → {slot}'**
  String addedToSlot(String name, String slot);

  /// No description provided for @settingsTitle.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settingsTitle;

  /// No description provided for @sectionProfile.
  ///
  /// In ko, this message translates to:
  /// **'내 정보'**
  String get sectionProfile;

  /// No description provided for @profileSummary.
  ///
  /// In ko, this message translates to:
  /// **'{sex} · {age}세 · {height}cm'**
  String profileSummary(String sex, String age, String height);

  /// No description provided for @editGoal.
  ///
  /// In ko, this message translates to:
  /// **'목표 다시 설정'**
  String get editGoal;

  /// No description provided for @editGoalDesc.
  ///
  /// In ko, this message translates to:
  /// **'기록은 그대로 두고 목표만 바꿔요'**
  String get editGoalDesc;

  /// No description provided for @sectionApp.
  ///
  /// In ko, this message translates to:
  /// **'앱'**
  String get sectionApp;

  /// No description provided for @language.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get language;

  /// No description provided for @langSystem.
  ///
  /// In ko, this message translates to:
  /// **'시스템 설정'**
  String get langSystem;

  /// No description provided for @checkinDay.
  ///
  /// In ko, this message translates to:
  /// **'체크인 요일'**
  String get checkinDay;

  /// No description provided for @notifications.
  ///
  /// In ko, this message translates to:
  /// **'체크인 알림'**
  String get notifications;

  /// No description provided for @notificationsDesc.
  ///
  /// In ko, this message translates to:
  /// **'모바일 앱에서 지원 예정'**
  String get notificationsDesc;

  /// No description provided for @units.
  ///
  /// In ko, this message translates to:
  /// **'단위'**
  String get units;

  /// No description provided for @sectionData.
  ///
  /// In ko, this message translates to:
  /// **'데이터'**
  String get sectionData;

  /// No description provided for @consentGiven.
  ///
  /// In ko, this message translates to:
  /// **'민감정보 저장 동의일: {date}'**
  String consentGiven(String date);

  /// No description provided for @deleteAll.
  ///
  /// In ko, this message translates to:
  /// **'모든 데이터 삭제'**
  String get deleteAll;

  /// No description provided for @deleteAllConfirm.
  ///
  /// In ko, this message translates to:
  /// **'체중, 식사, 목표 기록이 모두 지워지고 처음 화면으로 돌아가요. 되돌릴 수 없어요.'**
  String get deleteAllConfirm;

  /// No description provided for @sectionAbout.
  ///
  /// In ko, this message translates to:
  /// **'정보'**
  String get sectionAbout;

  /// No description provided for @version.
  ///
  /// In ko, this message translates to:
  /// **'버전'**
  String get version;

  /// No description provided for @browseMore.
  ///
  /// In ko, this message translates to:
  /// **'이 분류에는 {count}개가 있어요. 이름으로 검색해 보세요.'**
  String browseMore(String count);

  /// No description provided for @foodDataSource.
  ///
  /// In ko, this message translates to:
  /// **'출처: 식품의약품안전처 식품영양성분 데이터베이스'**
  String get foodDataSource;

  /// No description provided for @foodDataSourceDesc.
  ///
  /// In ko, this message translates to:
  /// **'음식 검색의 영양정보는 공공데이터포털에서 받은 데이터를 100g 기준으로 바꾼 값이에요.'**
  String get foodDataSourceDesc;

  /// No description provided for @savedMealsManage.
  ///
  /// In ko, this message translates to:
  /// **'내 식사 관리'**
  String get savedMealsManage;

  /// No description provided for @navCommunity.
  ///
  /// In ko, this message translates to:
  /// **'커뮤니티'**
  String get navCommunity;

  /// No description provided for @communityTitle.
  ///
  /// In ko, this message translates to:
  /// **'헬스장 커뮤니티'**
  String get communityTitle;

  /// No description provided for @communityIntro.
  ///
  /// In ko, this message translates to:
  /// **'같은 헬스장 사람들과 운동 메이트를 찾고 정보를 나눠요'**
  String get communityIntro;

  /// No description provided for @myGyms.
  ///
  /// In ko, this message translates to:
  /// **'내 헬스장'**
  String get myGyms;

  /// No description provided for @myGymsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'다니는 헬스장을 검색해서 내 헬스장에 추가해 보세요'**
  String get myGymsEmpty;

  /// No description provided for @gymSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'헬스장 이름이나 동네 (예: 강남 에이블짐)'**
  String get gymSearchHint;

  /// No description provided for @gymSearchEmpty.
  ///
  /// In ko, this message translates to:
  /// **'\'{q}\' 헬스장을 찾지 못했어요'**
  String gymSearchEmpty(String q);

  /// No description provided for @addGym.
  ///
  /// In ko, this message translates to:
  /// **'찾는 헬스장이 없나요? 직접 추가하기'**
  String get addGym;

  /// No description provided for @addGymTitle.
  ///
  /// In ko, this message translates to:
  /// **'헬스장 추가'**
  String get addGymTitle;

  /// No description provided for @gymName.
  ///
  /// In ko, this message translates to:
  /// **'헬스장 이름'**
  String get gymName;

  /// No description provided for @gymAddress.
  ///
  /// In ko, this message translates to:
  /// **'주소 (예: 서울 강남구 테헤란로 152)'**
  String get gymAddress;

  /// No description provided for @gymAdded.
  ///
  /// In ko, this message translates to:
  /// **'헬스장을 추가했어요'**
  String get gymAdded;

  /// No description provided for @gymMembers.
  ///
  /// In ko, this message translates to:
  /// **'멤버 {n}'**
  String gymMembers(String n);

  /// No description provided for @gymPosts.
  ///
  /// In ko, this message translates to:
  /// **'글 {n}'**
  String gymPosts(String n);

  /// No description provided for @joinGym.
  ///
  /// In ko, this message translates to:
  /// **'내 헬스장에 추가'**
  String get joinGym;

  /// No description provided for @joinedGym.
  ///
  /// In ko, this message translates to:
  /// **'내 헬스장'**
  String get joinedGym;

  /// No description provided for @leftGym.
  ///
  /// In ko, this message translates to:
  /// **'{name} 내 헬스장에서 뺐어요'**
  String leftGym(String name);

  /// No description provided for @leaveGym.
  ///
  /// In ko, this message translates to:
  /// **'내 헬스장에서 빼기'**
  String get leaveGym;

  /// No description provided for @boardEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 글이 없어요. 첫 글을 남겨 보세요!'**
  String get boardEmpty;

  /// No description provided for @writePost.
  ///
  /// In ko, this message translates to:
  /// **'글쓰기'**
  String get writePost;

  /// No description provided for @postHint.
  ///
  /// In ko, this message translates to:
  /// **'운동 메이트 찾기, 기구·붐비는 시간 정보, 궁금한 점을 자유롭게 남겨 주세요'**
  String get postHint;

  /// No description provided for @postSubmit.
  ///
  /// In ko, this message translates to:
  /// **'올리기'**
  String get postSubmit;

  /// No description provided for @photoLimit.
  ///
  /// In ko, this message translates to:
  /// **'사진은 {n}장까지 올릴 수 있어요'**
  String photoLimit(String n);

  /// No description provided for @commentsN.
  ///
  /// In ko, this message translates to:
  /// **'댓글 {n}'**
  String commentsN(String n);

  /// No description provided for @commentHint.
  ///
  /// In ko, this message translates to:
  /// **'댓글을 남겨 주세요'**
  String get commentHint;

  /// No description provided for @noComments.
  ///
  /// In ko, this message translates to:
  /// **'첫 댓글을 남겨 보세요'**
  String get noComments;

  /// No description provided for @edited.
  ///
  /// In ko, this message translates to:
  /// **'수정됨'**
  String get edited;

  /// No description provided for @justNow.
  ///
  /// In ko, this message translates to:
  /// **'방금'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In ko, this message translates to:
  /// **'{n}분 전'**
  String minutesAgo(String n);

  /// No description provided for @hoursAgo.
  ///
  /// In ko, this message translates to:
  /// **'{n}시간 전'**
  String hoursAgo(String n);

  /// No description provided for @daysAgo.
  ///
  /// In ko, this message translates to:
  /// **'{n}일 전'**
  String daysAgo(String n);

  /// No description provided for @report.
  ///
  /// In ko, this message translates to:
  /// **'신고'**
  String get report;

  /// No description provided for @reportContentTitle.
  ///
  /// In ko, this message translates to:
  /// **'신고 사유를 골라 주세요'**
  String get reportContentTitle;

  /// No description provided for @reasonSpam.
  ///
  /// In ko, this message translates to:
  /// **'스팸·광고'**
  String get reasonSpam;

  /// No description provided for @reasonAbuse.
  ///
  /// In ko, this message translates to:
  /// **'욕설·비하·괴롭힘'**
  String get reasonAbuse;

  /// No description provided for @reasonSexual.
  ///
  /// In ko, this message translates to:
  /// **'음란물·성적인 내용'**
  String get reasonSexual;

  /// No description provided for @reasonPrivacy.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 노출'**
  String get reasonPrivacy;

  /// No description provided for @reasonOther.
  ///
  /// In ko, this message translates to:
  /// **'기타 부적절한 내용'**
  String get reasonOther;

  /// No description provided for @reported.
  ///
  /// In ko, this message translates to:
  /// **'신고했어요. 여러 명이 신고하면 바로 가려지고, 운영자가 24시간 안에 확인해요.'**
  String get reported;

  /// No description provided for @blockUser.
  ///
  /// In ko, this message translates to:
  /// **'이 사람 차단'**
  String get blockUser;

  /// No description provided for @blockConfirm.
  ///
  /// In ko, this message translates to:
  /// **'{name} 님을 차단할까요? 이 사람의 글과 댓글이 더 이상 보이지 않아요.'**
  String blockConfirm(String name);

  /// No description provided for @blockAction.
  ///
  /// In ko, this message translates to:
  /// **'차단'**
  String get blockAction;

  /// No description provided for @blocked.
  ///
  /// In ko, this message translates to:
  /// **'차단했어요'**
  String get blocked;

  /// No description provided for @deletePostConfirm.
  ///
  /// In ko, this message translates to:
  /// **'이 글을 삭제할까요? 사진과 댓글도 함께 지워져요.'**
  String get deletePostConfirm;

  /// No description provided for @deleteCommentConfirm.
  ///
  /// In ko, this message translates to:
  /// **'댓글을 삭제할까요?'**
  String get deleteCommentConfirm;

  /// No description provided for @postDeleted.
  ///
  /// In ko, this message translates to:
  /// **'글을 삭제했어요'**
  String get postDeleted;

  /// No description provided for @editPost.
  ///
  /// In ko, this message translates to:
  /// **'수정'**
  String get editPost;

  /// No description provided for @communitySignIn.
  ///
  /// In ko, this message translates to:
  /// **'글을 쓰고 댓글을 달려면 로그인해 주세요'**
  String get communitySignIn;

  /// No description provided for @communitySignInCta.
  ///
  /// In ko, this message translates to:
  /// **'로그인하기'**
  String get communitySignInCta;

  /// No description provided for @setupTitle.
  ///
  /// In ko, this message translates to:
  /// **'커뮤니티에서 쓸 닉네임'**
  String get setupTitle;

  /// No description provided for @nicknameHint.
  ///
  /// In ko, this message translates to:
  /// **'2~12자, 한글·영문·숫자'**
  String get nicknameHint;

  /// No description provided for @nicknameInvalid.
  ///
  /// In ko, this message translates to:
  /// **'2~12자의 한글, 영문, 숫자로 정해 주세요'**
  String get nicknameInvalid;

  /// No description provided for @nicknameTaken.
  ///
  /// In ko, this message translates to:
  /// **'이미 쓰고 있는 닉네임이에요'**
  String get nicknameTaken;

  /// No description provided for @bannedError.
  ///
  /// In ko, this message translates to:
  /// **'커뮤니티 규칙 위반으로 글쓰기가 중단된 계정이에요. 설정 → 문의하기로 알려 주세요.'**
  String get bannedError;

  /// No description provided for @discardDraftTitle.
  ///
  /// In ko, this message translates to:
  /// **'작성 중인 글을 버릴까요?'**
  String get discardDraftTitle;

  /// No description provided for @discardDraftBody.
  ///
  /// In ko, this message translates to:
  /// **'지금 닫으면 쓴 내용과 고른 사진이 사라져요.'**
  String get discardDraftBody;

  /// No description provided for @keepWriting.
  ///
  /// In ko, this message translates to:
  /// **'계속 쓰기'**
  String get keepWriting;

  /// No description provided for @discardDraft.
  ///
  /// In ko, this message translates to:
  /// **'버리기'**
  String get discardDraft;

  /// No description provided for @searchPosts.
  ///
  /// In ko, this message translates to:
  /// **'글 검색'**
  String get searchPosts;

  /// No description provided for @searchPostsHint.
  ///
  /// In ko, this message translates to:
  /// **'이 게시판에서 찾을 말'**
  String get searchPostsHint;

  /// No description provided for @searchPostsCount.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과 {n}개'**
  String searchPostsCount(String n);

  /// No description provided for @searchPostsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'{q} 들어간 글이 없어요'**
  String searchPostsEmpty(String q);

  /// No description provided for @sortNewest.
  ///
  /// In ko, this message translates to:
  /// **'최신순'**
  String get sortNewest;

  /// No description provided for @sortPopular.
  ///
  /// In ko, this message translates to:
  /// **'인기순'**
  String get sortPopular;

  /// No description provided for @popularEmpty.
  ///
  /// In ko, this message translates to:
  /// **'최근 30일 동안 좋아요를 받은 글이 아직 없어요'**
  String get popularEmpty;

  /// No description provided for @termsOfUse.
  ///
  /// In ko, this message translates to:
  /// **'이용약관'**
  String get termsOfUse;

  /// No description provided for @readTerms.
  ///
  /// In ko, this message translates to:
  /// **'이용약관 전체 보기'**
  String get readTerms;

  /// No description provided for @contactUs.
  ///
  /// In ko, this message translates to:
  /// **'문의하기'**
  String get contactUs;

  /// No description provided for @contactUsSub.
  ///
  /// In ko, this message translates to:
  /// **'버그, 신고, 제안 모두 보내 주세요'**
  String get contactUsSub;

  /// No description provided for @contactSubject.
  ///
  /// In ko, this message translates to:
  /// **'알아서핏 문의'**
  String get contactSubject;

  /// No description provided for @contactCopied.
  ///
  /// In ko, this message translates to:
  /// **'메일 앱이 없어서 주소를 복사했어요: {email}'**
  String contactCopied(String email);

  /// No description provided for @rulesTitle.
  ///
  /// In ko, this message translates to:
  /// **'커뮤니티 규칙'**
  String get rulesTitle;

  /// No description provided for @rulesBody.
  ///
  /// In ko, this message translates to:
  /// **'· 욕설, 비하, 괴롭힘, 음란물, 불법·상업 광고는 허용되지 않아요.\n· 다른 사람의 연락처나 사진 같은 개인정보를 올리지 마세요.\n· 만남을 강요하거나 불쾌감을 주는 행동은 금지예요.\n· 규칙을 어긴 글은 경고 없이 지워지고, 작성자는 이용이 중단돼요(무관용). 신고는 24시간 안에 확인해요.'**
  String get rulesBody;

  /// No description provided for @agreeRules.
  ///
  /// In ko, this message translates to:
  /// **'규칙에 동의하고 시작하기'**
  String get agreeRules;

  /// No description provided for @rateLimited.
  ///
  /// In ko, this message translates to:
  /// **'조금 뒤에 다시 올려 주세요 (10분에 5개까지)'**
  String get rateLimited;

  /// No description provided for @blockedWordsError.
  ///
  /// In ko, this message translates to:
  /// **'허용되지 않는 표현이 있어요. 고쳐서 다시 올려 주세요.'**
  String get blockedWordsError;

  /// No description provided for @badImage.
  ///
  /// In ko, this message translates to:
  /// **'JPG, PNG 사진만 올릴 수 있어요 (5MB 이하)'**
  String get badImage;

  /// No description provided for @communityError.
  ///
  /// In ko, this message translates to:
  /// **'연결하지 못했어요. 잠시 후 다시 시도해 주세요.'**
  String get communityError;

  /// No description provided for @retry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get retry;

  /// No description provided for @tagAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get tagAll;

  /// No description provided for @tagFree.
  ///
  /// In ko, this message translates to:
  /// **'잡담'**
  String get tagFree;

  /// No description provided for @tagMate.
  ///
  /// In ko, this message translates to:
  /// **'운동메이트'**
  String get tagMate;

  /// No description provided for @tagQuestion.
  ///
  /// In ko, this message translates to:
  /// **'질문'**
  String get tagQuestion;

  /// No description provided for @tagInfo.
  ///
  /// In ko, this message translates to:
  /// **'정보'**
  String get tagInfo;

  /// No description provided for @tagReview.
  ///
  /// In ko, this message translates to:
  /// **'후기'**
  String get tagReview;

  /// No description provided for @tagHintFree.
  ///
  /// In ko, this message translates to:
  /// **'오늘 운동 어땠나요? 자유롭게 이야기해요'**
  String get tagHintFree;

  /// No description provided for @tagHintMate.
  ///
  /// In ko, this message translates to:
  /// **'요일, 시간, 운동 부위를 적으면 메이트를 찾기 쉬워요'**
  String get tagHintMate;

  /// No description provided for @tagHintQuestion.
  ///
  /// In ko, this message translates to:
  /// **'궁금한 점을 구체적으로 적어 주세요'**
  String get tagHintQuestion;

  /// No description provided for @tagHintInfo.
  ///
  /// In ko, this message translates to:
  /// **'붐비는 시간, 기구 상태, 이벤트 소식을 나눠요'**
  String get tagHintInfo;

  /// No description provided for @tagHintReview.
  ///
  /// In ko, this message translates to:
  /// **'PT, 기구, 수업 후기를 남겨요'**
  String get tagHintReview;

  /// No description provided for @chooseTag.
  ///
  /// In ko, this message translates to:
  /// **'어떤 글인가요?'**
  String get chooseTag;

  /// No description provided for @heroTitle.
  ///
  /// In ko, this message translates to:
  /// **'오늘 우리 헬스장엔\n무슨 일이?'**
  String get heroTitle;

  /// No description provided for @heroMyGyms.
  ///
  /// In ko, this message translates to:
  /// **'내 헬스장 {n}'**
  String heroMyGyms(String n);

  /// No description provided for @heroNewToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘 새 글 {n}'**
  String heroNewToday(String n);

  /// No description provided for @findGym.
  ///
  /// In ko, this message translates to:
  /// **'헬스장 찾기'**
  String get findGym;

  /// No description provided for @myGymsNews.
  ///
  /// In ko, this message translates to:
  /// **'📣 내 헬스장 소식'**
  String get myGymsNews;

  /// No description provided for @feedEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 새 글이 없어요. 먼저 인사를 남겨 보세요!'**
  String get feedEmpty;

  /// No description provided for @startTitle.
  ///
  /// In ko, this message translates to:
  /// **'우리 헬스장 커뮤니티 시작하기'**
  String get startTitle;

  /// No description provided for @startStep1.
  ///
  /// In ko, this message translates to:
  /// **'다니는 헬스장을 검색해요'**
  String get startStep1;

  /// No description provided for @startStep2.
  ///
  /// In ko, this message translates to:
  /// **'내 헬스장에 추가해요'**
  String get startStep2;

  /// No description provided for @startStep3.
  ///
  /// In ko, this message translates to:
  /// **'운동 메이트를 찾고 정보를 나눠요'**
  String get startStep3;

  /// No description provided for @newBadge.
  ///
  /// In ko, this message translates to:
  /// **'새 글'**
  String get newBadge;

  /// No description provided for @authorBadge.
  ///
  /// In ko, this message translates to:
  /// **'작성자'**
  String get authorBadge;

  /// No description provided for @setupSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'헬스장 친구들에게 보이는 이름이에요'**
  String get setupSubtitle;

  /// No description provided for @searchResults.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과 {n}'**
  String searchResults(String n);

  /// No description provided for @replyAction.
  ///
  /// In ko, this message translates to:
  /// **'답글 달기'**
  String get replyAction;

  /// No description provided for @replyingTo.
  ///
  /// In ko, this message translates to:
  /// **'{name}님에게 답글'**
  String replyingTo(String name);

  /// No description provided for @replyHint.
  ///
  /// In ko, this message translates to:
  /// **'답글을 남겨 주세요'**
  String get replyHint;

  /// No description provided for @repliesN.
  ///
  /// In ko, this message translates to:
  /// **'답글 {n}'**
  String repliesN(String n);

  /// No description provided for @tabMyGyms.
  ///
  /// In ko, this message translates to:
  /// **'내 헬스장'**
  String get tabMyGyms;

  /// No description provided for @tabLounge.
  ///
  /// In ko, this message translates to:
  /// **'운동 라운지'**
  String get tabLounge;

  /// No description provided for @loungeTitle.
  ///
  /// In ko, this message translates to:
  /// **'운동 라운지'**
  String get loungeTitle;

  /// No description provided for @loungeSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'헬스장 상관없이 모든 회원이 함께 이야기해요'**
  String get loungeSubtitle;

  /// No description provided for @loungeCategories.
  ///
  /// In ko, this message translates to:
  /// **'💪 운동별 게시판'**
  String get loungeCategories;

  /// No description provided for @loungeHot.
  ///
  /// In ko, this message translates to:
  /// **'🔥 이번 주 인기글'**
  String get loungeHot;

  /// No description provided for @loungeLatest.
  ///
  /// In ko, this message translates to:
  /// **'✨ 라운지 최신글'**
  String get loungeLatest;

  /// No description provided for @loungeEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 글이 없어요. 첫 글을 남겨 보세요!'**
  String get loungeEmpty;

  /// No description provided for @loungeBoardBadge.
  ///
  /// In ko, this message translates to:
  /// **'운동 라운지 · 누구나 참여'**
  String get loungeBoardBadge;

  /// No description provided for @topicHealth.
  ///
  /// In ko, this message translates to:
  /// **'헬스'**
  String get topicHealth;

  /// No description provided for @topicCrossfit.
  ///
  /// In ko, this message translates to:
  /// **'크로스핏'**
  String get topicCrossfit;

  /// No description provided for @topicRunning.
  ///
  /// In ko, this message translates to:
  /// **'러닝'**
  String get topicRunning;

  /// No description provided for @topicYoga.
  ///
  /// In ko, this message translates to:
  /// **'요가'**
  String get topicYoga;

  /// No description provided for @topicPilates.
  ///
  /// In ko, this message translates to:
  /// **'필라테스'**
  String get topicPilates;

  /// No description provided for @topicDiet.
  ///
  /// In ko, this message translates to:
  /// **'다이어트·식단'**
  String get topicDiet;

  /// No description provided for @topicHome.
  ///
  /// In ko, this message translates to:
  /// **'홈트'**
  String get topicHome;

  /// No description provided for @topicSwimming.
  ///
  /// In ko, this message translates to:
  /// **'수영'**
  String get topicSwimming;

  /// No description provided for @topicClimbing.
  ///
  /// In ko, this message translates to:
  /// **'클라이밍'**
  String get topicClimbing;

  /// No description provided for @topicCycling.
  ///
  /// In ko, this message translates to:
  /// **'자전거'**
  String get topicCycling;

  /// No description provided for @topicCombat.
  ///
  /// In ko, this message translates to:
  /// **'복싱·격투기'**
  String get topicCombat;

  /// No description provided for @topicFree.
  ///
  /// In ko, this message translates to:
  /// **'자유수다'**
  String get topicFree;

  /// No description provided for @gymLimitTitle.
  ///
  /// In ko, this message translates to:
  /// **'내 헬스장은 {max}개까지예요'**
  String gymLimitTitle(String max);

  /// No description provided for @gymLimitBody.
  ///
  /// In ko, this message translates to:
  /// **'하나를 빼면 {name} 추가할게요'**
  String gymLimitBody(String name);

  /// No description provided for @gymLimitError.
  ///
  /// In ko, this message translates to:
  /// **'내 헬스장은 3개까지 추가할 수 있어요'**
  String get gymLimitError;

  /// No description provided for @swapGym.
  ///
  /// In ko, this message translates to:
  /// **'빼고 추가'**
  String get swapGym;

  /// No description provided for @inviteFriends.
  ///
  /// In ko, this message translates to:
  /// **'친구 초대'**
  String get inviteFriends;

  /// No description provided for @inviteTitle.
  ///
  /// In ko, this message translates to:
  /// **'친구와 같이 운동해요'**
  String get inviteTitle;

  /// No description provided for @inviteBody.
  ///
  /// In ko, this message translates to:
  /// **'링크를 보내면 친구가 바로 들어올 수 있어요'**
  String get inviteBody;

  /// No description provided for @inviteApp.
  ///
  /// In ko, this message translates to:
  /// **'앱 초대하기'**
  String get inviteApp;

  /// No description provided for @inviteAppDesc.
  ///
  /// In ko, this message translates to:
  /// **'카톡·문자로 알아서핏을 알려요'**
  String get inviteAppDesc;

  /// No description provided for @inviteGym.
  ///
  /// In ko, this message translates to:
  /// **'{name} 게시판 초대'**
  String inviteGym(String name);

  /// No description provided for @inviteGymDesc.
  ///
  /// In ko, this message translates to:
  /// **'같은 헬스장 친구를 우리 게시판으로'**
  String get inviteGymDesc;

  /// No description provided for @inviteAppText.
  ///
  /// In ko, this message translates to:
  /// **'나 요즘 알아서핏으로 식단이랑 운동 기록하는데 같이 해볼래? 헬스장 친구들이랑 이야기도 할 수 있어 💪\n{link}'**
  String inviteAppText(String link);

  /// No description provided for @inviteGymText.
  ///
  /// In ko, this message translates to:
  /// **'알아서핏 \'{name}\' 게시판에서 같이 운동해요! 운동메이트 구하고 정보도 나눠요 💪\n{link}'**
  String inviteGymText(String name, String link);

  /// No description provided for @linkCopied.
  ///
  /// In ko, this message translates to:
  /// **'링크를 복사했어요. 친구에게 붙여넣어 보내세요!'**
  String get linkCopied;

  /// No description provided for @shareBoard.
  ///
  /// In ko, this message translates to:
  /// **'공유'**
  String get shareBoard;

  /// No description provided for @chooseTopic.
  ///
  /// In ko, this message translates to:
  /// **'어느 게시판에 쓸까요?'**
  String get chooseTopic;

  /// No description provided for @loungeHotEmpty.
  ///
  /// In ko, this message translates to:
  /// **'이번 주 인기글이 아직 없어요. 좋아요로 골라 주세요!'**
  String get loungeHotEmpty;

  /// No description provided for @allBoards.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get allBoards;

  /// No description provided for @editProfile.
  ///
  /// In ko, this message translates to:
  /// **'프로필 편집'**
  String get editProfile;

  /// No description provided for @editProfileSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'커뮤니티에서 보이는 사진과 닉네임이에요'**
  String get editProfileSubtitle;

  /// No description provided for @nicknameLabel.
  ///
  /// In ko, this message translates to:
  /// **'닉네임'**
  String get nicknameLabel;

  /// No description provided for @choosePhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진 선택'**
  String get choosePhoto;

  /// No description provided for @removePhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진 삭제'**
  String get removePhoto;

  /// No description provided for @profileSaved.
  ///
  /// In ko, this message translates to:
  /// **'프로필을 저장했어요'**
  String get profileSaved;

  /// No description provided for @myProfile.
  ///
  /// In ko, this message translates to:
  /// **'내 프로필'**
  String get myProfile;

  /// No description provided for @favoritesOnly.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기만'**
  String get favoritesOnly;

  /// No description provided for @favoritesHint.
  ///
  /// In ko, this message translates to:
  /// **'게시판의 ☆를 눌러 자주 보는 운동을 즐겨찾기 해 보세요'**
  String get favoritesHint;

  /// No description provided for @favoriteAdd.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기'**
  String get favoriteAdd;

  /// No description provided for @favoriteAdded.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기에 추가했어요'**
  String get favoriteAdded;

  /// No description provided for @myActivity.
  ///
  /// In ko, this message translates to:
  /// **'내 활동'**
  String get myActivity;

  /// No description provided for @myPostsTab.
  ///
  /// In ko, this message translates to:
  /// **'내가 쓴 글'**
  String get myPostsTab;

  /// No description provided for @myCommentsTab.
  ///
  /// In ko, this message translates to:
  /// **'내 댓글'**
  String get myCommentsTab;

  /// No description provided for @myPostsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 쓴 글이 없어요. 첫 글을 남겨 보세요!'**
  String get myPostsEmpty;

  /// No description provided for @myCommentsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 단 댓글이 없어요'**
  String get myCommentsEmpty;

  /// No description provided for @onPost.
  ///
  /// In ko, this message translates to:
  /// **'원글'**
  String get onPost;

  /// No description provided for @postGone.
  ///
  /// In ko, this message translates to:
  /// **'삭제되었거나 볼 수 없는 글이에요'**
  String get postGone;

  /// No description provided for @notificationsTitle.
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 알림이 없어요. 글을 쓰고 댓글을 달면 여기서 소식을 알려 드릴게요!'**
  String get notificationsEmpty;

  /// No description provided for @someone.
  ///
  /// In ko, this message translates to:
  /// **'누군가'**
  String get someone;

  /// No description provided for @andOthers.
  ///
  /// In ko, this message translates to:
  /// **'{name}님 외 {n}명'**
  String andOthers(String name, String n);

  /// No description provided for @nameSuffix.
  ///
  /// In ko, this message translates to:
  /// **'{name}님'**
  String nameSuffix(String name);

  /// No description provided for @notifPostLike.
  ///
  /// In ko, this message translates to:
  /// **'{who}이 내 글을 좋아해요'**
  String notifPostLike(String who);

  /// No description provided for @notifComment.
  ///
  /// In ko, this message translates to:
  /// **'{who}이 내 글에 댓글을 남겼어요'**
  String notifComment(String who);

  /// No description provided for @notifReply.
  ///
  /// In ko, this message translates to:
  /// **'{who}이 내 댓글에 답글을 남겼어요'**
  String notifReply(String who);

  /// No description provided for @notifCommentLike.
  ///
  /// In ko, this message translates to:
  /// **'{who}이 내 댓글을 좋아해요'**
  String notifCommentLike(String who);

  /// No description provided for @notifHot.
  ///
  /// In ko, this message translates to:
  /// **'내 글이 인기글에 올랐어요!'**
  String get notifHot;

  /// No description provided for @hotNow.
  ///
  /// In ko, this message translates to:
  /// **'지금 뜨는 인기글'**
  String get hotNow;

  /// No description provided for @hotBadge.
  ///
  /// In ko, this message translates to:
  /// **'HOT'**
  String get hotBadge;

  /// No description provided for @notificationsSignIn.
  ///
  /// In ko, this message translates to:
  /// **'로그인하면 내 글과 댓글 소식을 알려 드려요'**
  String get notificationsSignIn;
}

class _LDelegate extends LocalizationsDelegate<L> {
  const _LDelegate();

  @override
  Future<L> load(Locale locale) {
    return SynchronousFuture<L>(lookupL(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_LDelegate old) => false;
}

L lookupL(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return LEn();
    case 'ko':
      return LKo();
  }

  throw FlutterError(
    'L.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
