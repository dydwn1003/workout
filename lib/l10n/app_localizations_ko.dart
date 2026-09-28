// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class LKo extends L {
  LKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => 'Adapt';

  @override
  String get next => '다음';

  @override
  String get back => '이전';

  @override
  String get save => '저장';

  @override
  String get cancel => '취소';

  @override
  String get delete => '삭제';

  @override
  String get confirm => '확인';

  @override
  String get undo => '되돌리기';

  @override
  String get kcal => 'kcal';

  @override
  String get navToday => '오늘';

  @override
  String get navTrend => '트렌드';

  @override
  String get navCheckin => '체크인';

  @override
  String get navSettings => '설정';

  @override
  String get welcomeTitle => '매주 알아서 맞춰주는\n칼로리 코치';

  @override
  String get welcomeBody =>
      '체중과 식사만 기록하세요. 실제로 쓰는 에너지를 계산해서 매주 목표 칼로리를 다시 맞춰 드릴게요.';

  @override
  String get disclaimer =>
      '이 앱은 의학적 조언을 제공하지 않아요. 질환이 있거나 임신·수유 중이라면 먼저 전문가와 상담해 주세요.';

  @override
  String get consentLabel => '체중·체성분 같은 건강 정보를 이 기기에 저장하는 데 동의해요 (민감정보)';

  @override
  String get getStarted => '시작해볼까요?';

  @override
  String get tryDemo => '샘플 데이터로 먼저 둘러보기';

  @override
  String get stepGoalTitle => '어떤 목표를 가지고 있나요?';

  @override
  String get goalLose => '감량';

  @override
  String get goalLoseDesc => '체중을 천천히 줄여요';

  @override
  String get goalMaintain => '유지';

  @override
  String get goalMaintainDesc => '지금 체중을 지켜요';

  @override
  String get goalGain => '증량';

  @override
  String get goalGainDesc => '근육과 체중을 늘려요';

  @override
  String get goalRecomp => '체성분 개선';

  @override
  String get goalRecompDesc => '체지방은 줄이고 근육은 지켜요';

  @override
  String get stepBodyTitle => '지금 몸 상태를 알려주세요';

  @override
  String get male => '남성';

  @override
  String get female => '여성';

  @override
  String get birthYear => '출생연도';

  @override
  String get heightCm => '키 (cm)';

  @override
  String get weightKg => '체중 (kg)';

  @override
  String get bodyFatOptional => '체지방 %(선택)';

  @override
  String get smmOptional => '골격근 kg(선택)';

  @override
  String get bodyCompHint => '체성분은 같은 기기, 같은 조건(주 1회, 아침 공복)에서 재면 가장 정확해요.';

  @override
  String get stepTargetTitle => '목표를 정해볼까요?';

  @override
  String get targetByWeight => '목표 체중';

  @override
  String get targetByBodyFat => '목표 체지방률';

  @override
  String get targetWeightField => '목표 체중 (kg)';

  @override
  String get targetBodyFatField => '목표 체지방률 (%)';

  @override
  String targetBfResult(String kg) {
    return '근육(제지방량)을 유지하면 목표 체중은 약 ${kg}kg이에요';
  }

  @override
  String get targetBfNeedsCurrent => '체지방률 목표는 현재 체지방률을 입력해야 쓸 수 있어요';

  @override
  String get maintainNoTarget => '유지 목표는 따로 목표값이 필요 없어요. 지금 체중 근처를 지켜드릴게요.';

  @override
  String get stepPaceTitle => '어떤 속도로 갈까요?';

  @override
  String get paceRelaxed => '여유롭게';

  @override
  String get paceNormal => '보통';

  @override
  String get paceFast => '빠르게';

  @override
  String paceDesc(String kg, String pct) {
    return '주당 약 ${kg}kg ($pct%)';
  }

  @override
  String get paceHint => '처음이라면 \'보통\'을 추천해요. 너무 빠르면 근손실과 요요 위험이 커져요.';

  @override
  String get stepActivityTitle => '일주일에 운동을 얼마나 하나요?';

  @override
  String get strength => '근력운동';

  @override
  String get cardio => '유산소';

  @override
  String get timesPerWeek => '회 / 주';

  @override
  String get activityHint => '처음 목표를 계산할 때만 써요. 이후엔 실제 기록으로 맞춰져요.';

  @override
  String get stepResultTitle => '첫 번째 목표가 나왔어요!';

  @override
  String get dailyTarget => '하루 목표';

  @override
  String get protein => '단백질';

  @override
  String get carbs => '탄수화물';

  @override
  String get fat => '지방';

  @override
  String get estTdee => '추정 소비량';

  @override
  String get etaLabel => '목표 도달 예상';

  @override
  String etaWeeks(String min, String max) {
    return '약 $min~$max주 후';
  }

  @override
  String get etaReached => '거의 도착했어요!';

  @override
  String get etaUnknown => '아직 예측하기 어려워요';

  @override
  String floorNotice(String kcal) {
    return '안전 하한($kcal kcal)에 맞췄어요. 속도를 한 단계 낮추는 걸 추천해요.';
  }

  @override
  String get resultNote =>
      '첫 목표는 공식으로 계산한 추정치예요. 2~4주 기록이 쌓이면 내 몸에 맞게 매주 조정돼요.';

  @override
  String get issueUnderage => '만 18세 미만은 사용할 수 없어요.';

  @override
  String get issueBmiLow => '현재 체중에서는 감량 목표를 만들 수 없어요. 유지를 선택해 주세요.';

  @override
  String get issueTargetBmiLow => '목표 체중이 건강 범위보다 낮아요. 목표를 조금 올려주세요.';

  @override
  String get issueTargetDirection => '목표 체중이 선택한 목표와 방향이 맞지 않아요.';

  @override
  String get startApp => '시작하기';

  @override
  String get todayGreeting => '오늘도 차근차근!';

  @override
  String get kcalLeft => '남은 칼로리';

  @override
  String get kcalOver => '초과';

  @override
  String eatenOfTarget(String eaten, String target) {
    return '$eaten / $target kcal';
  }

  @override
  String get weightToday => '오늘 체중';

  @override
  String get logWeight => '체중 기록하기';

  @override
  String trendKg(String kg) {
    return '추세 ${kg}kg';
  }

  @override
  String get checkinDueBanner => '주간 체크인 시간이에요! 이번 주 목표를 확인해 보세요';

  @override
  String get checkinGo => '확인하기';

  @override
  String get mealsTitle => '오늘 먹은 것';

  @override
  String get noMealsYet => '아직 기록이 없어요.\n아래 버튼으로 첫 끼를 남겨보세요!';

  @override
  String get addMeal => '식사 기록';

  @override
  String get mealDeleted => '삭제했어요';

  @override
  String get tabText => '텍스트';

  @override
  String get tabSaved => '내 식사';

  @override
  String get tabManual => '직접 입력';

  @override
  String get tabPhoto => '사진';

  @override
  String get textHint => '예: 현미밥 1공기, 닭가슴살 150g, 계란 2개';

  @override
  String get estimate => '계산하기';

  @override
  String get estimateNote => '간이 음식 사전으로 추정했어요. 값은 자유롭게 고칠 수 있어요.';

  @override
  String unmatchedNote(String items) {
    return '모르는 음식은 0 kcal로 두었어요: $items';
  }

  @override
  String get mealName => '이름';

  @override
  String get kcalField => '칼로리 (kcal)';

  @override
  String get proteinField => '단백질 (g)';

  @override
  String get carbsField => '탄수화물 (g)';

  @override
  String get fatField => '지방 (g)';

  @override
  String get saveAsMyMeal => '\'내 식사\'에도 저장하기';

  @override
  String get addToToday => '추가하기';

  @override
  String get noSavedMeals => '저장된 식사가 없어요.\n자주 먹는 식사를 저장하면 한 번에 추가할 수 있어요.';

  @override
  String added(String name) {
    return '$name 추가!';
  }

  @override
  String get photoSoon => '사진 분석은 곧 만나요';

  @override
  String get photoSoonDesc =>
      '서버가 연결되면 사진 한 장으로 음식과 칼로리를 추정해 드릴게요. (무료 하루 3장, 사진은 분석 후 바로 폐기)';

  @override
  String get weightTitle => '체중 기록';

  @override
  String get bodyFatField => '체지방률 (%)';

  @override
  String get smmField => '골격근량 (kg)';

  @override
  String get moreBodyComp => '체성분도 입력하기';

  @override
  String get healthSync => '건강앱 자동 연동';

  @override
  String get healthSyncSoon => '준비 중 · 모바일 앱에서 지원 예정';

  @override
  String get weightSaved => '체중을 기록했어요';

  @override
  String get trendTitle => '트렌드';

  @override
  String get range4w => '4주';

  @override
  String get range12w => '12주';

  @override
  String get rangeAll => '전체';

  @override
  String get legendRaw => '측정값';

  @override
  String get legendTrend => '추세';

  @override
  String get legendGoal => '목표';

  @override
  String get currentTrend => '현재 추세';

  @override
  String get weeklyChange => '지난 7일';

  @override
  String get goalWeight => '목표 체중';

  @override
  String get bodyCompTitle => '체성분 추이';

  @override
  String get noBodyComp => '체성분을 입력하면 여기서 추이를 볼 수 있어요.';

  @override
  String get muscleWarn =>
      '최근 4주간 골격근량이 측정 오차보다 크게 줄었어요. 감량 속도를 낮추고 단백질 섭취를 확인해 보세요.';

  @override
  String get notEnoughData => '체중을 2일 이상 기록하면 그래프가 나타나요';

  @override
  String get weightHistory => '체중 기록';

  @override
  String get trendExplain =>
      '매일 체중은 수분 때문에 오르락내리락해요. 추세선은 그 흔들림을 걸러낸 진짜 방향이에요.';

  @override
  String get checkinTitle => '주간 체크인';

  @override
  String nextCheckin(String date) {
    return '다음 체크인: $date';
  }

  @override
  String get checkinPreview => '아직 체크인 날은 아니지만 미리 볼 수 있어요';

  @override
  String get avgIntake => '평균 섭취';

  @override
  String lastNDays(String days) {
    return '최근 $days일';
  }

  @override
  String get trendChange => '추세 체중 변화';

  @override
  String get confidence => '신뢰도';

  @override
  String get confHigh => '높음';

  @override
  String get confMedium => '보통';

  @override
  String get confLow => '낮음';

  @override
  String get currentTarget => '현재 목표';

  @override
  String get newTarget => '새 목표 제안';

  @override
  String reasonLowConfidence(String logged, String weighs) {
    return '이번 주는 기록이 조금 부족해요 (식사 $logged/7일, 체중 $weighs회). 목표는 그대로 둘게요. 식사 5일, 체중 3회 이상이면 조정할 수 있어요.';
  }

  @override
  String reasonPlateau(String tdee) {
    return '체중 추세가 2주째 거의 그대로예요. 계산해 보니 소비량이 약 $tdee kcal로 낮아진 것 같아요. 목표를 살짝 낮춰볼까요?';
  }

  @override
  String reasonTdeeUp(String tdee) {
    return '생각보다 에너지를 더 쓰고 있어요! 추정 소비량을 $tdee kcal로 올렸어요.';
  }

  @override
  String reasonTdeeDown(String tdee) {
    return '추정 소비량이 $tdee kcal로 조금 내려갔어요. 목표를 그에 맞게 조정할게요.';
  }

  @override
  String get reasonOnTrack => '계획대로 잘 가고 있어요! 목표는 거의 그대로예요.';

  @override
  String floorHitCheckin(String kcal) {
    return '안전 하한 때문에 $kcal kcal 아래로는 내리지 않았어요. 속도를 낮추는 걸 고려해 보세요.';
  }

  @override
  String get accept => '수락';

  @override
  String get keep => '유지';

  @override
  String get adjust => '직접 조정';

  @override
  String get manualKcalTitle => '목표 칼로리 직접 입력';

  @override
  String manualKcalFloor(String kcal) {
    return '최소 $kcal kcal 이상이어야 해요';
  }

  @override
  String get appliedAccept => '새 목표를 적용했어요!';

  @override
  String get appliedKeep => '기존 목표를 유지해요';

  @override
  String get appliedManual => '직접 정한 목표를 적용했어요';

  @override
  String get howCalculated => '어떻게 계산했나요?';

  @override
  String howCalculatedBody(
    String window,
    String intake,
    String delta,
    String obs,
    String formula,
    String est,
  ) {
    return '최근 $window일 동안 평균 $intake kcal를 먹었고 추세 체중이 ${delta}kg 변했어요. 1kg ≈ 7,700 kcal로 환산하면 실제 소비량은 약 $obs kcal예요. 이를 공식 추정치($formula kcal)와 섞고, 한 주 변화폭을 ±150 kcal로 제한해서 $est kcal로 정했어요.';
  }

  @override
  String noObservedYet(String formula) {
    return '아직 실측 데이터가 부족해서 공식 추정치($formula kcal)를 기준으로 해요. 2주 정도 꾸준히 기록하면 실제 소비량을 계산할 수 있어요.';
  }

  @override
  String get planHistory => '목표 변화 기록';

  @override
  String get statusInitial => '시작';

  @override
  String get statusAccepted => '수락';

  @override
  String get statusKept => '유지';

  @override
  String get statusManual => '직접';

  @override
  String get checkinDone => '이번 주 체크인 완료!';

  @override
  String get checkinDoneDesc => '다음 체크인까지 꾸준히 기록해 주세요. 기록이 많을수록 정확해져요.';

  @override
  String get checkinAnyway => '그래도 지금 다시 계산해 보기';

  @override
  String get backToToday => '오늘로';

  @override
  String streakTitle(String days) {
    return '연속 $days일째 기록 중!';
  }

  @override
  String get streakZero => '오늘 첫 기록으로 연속 기록을 시작해요';

  @override
  String weekMeals(String n) {
    return '식사 $n/7일';
  }

  @override
  String weekWeighs(String n) {
    return '체중 $n회';
  }

  @override
  String get weekLogHint => '식사 5일 · 체중 3회 이상 기록하면 체크인에서 목표를 조정할 수 있어요';

  @override
  String get weekLogReady => '이번 주 기록이 충분해요. 체크인 때 정확하게 조정할 수 있어요!';

  @override
  String get editMeal => '식사 수정';

  @override
  String get mealUpdated => '수정했어요';

  @override
  String get recentMeals => '최근 먹은 것';

  @override
  String get savedMealsTitle => '내 식사';

  @override
  String get mealsOnDay => '이날 먹은 것';

  @override
  String get weightOnDay => '이날 체중';

  @override
  String get noMealsPast => '이날은 기록이 없어요.\n아래 버튼으로 빠진 식사를 채울 수 있어요.';

  @override
  String get pastDayGreeting => '지난 기록 채우기';

  @override
  String get workoutsTitle => '운동';

  @override
  String get workoutsOnDay => '이날 운동';

  @override
  String get logWorkout => '운동 기록';

  @override
  String get noWorkouts => '아직 운동 기록이 없어요';

  @override
  String minutesN(String n) {
    return '$n분';
  }

  @override
  String get workoutMinutes => '운동 시간';

  @override
  String workoutAdded(String type, String minutes) {
    return '$type $minutes분 기록!';
  }

  @override
  String get workoutDeleted => '운동 기록을 지웠어요';

  @override
  String get workoutNoCalories =>
      '운동 칼로리는 목표에 더하지 않아요. 운동으로 쓴 에너지는 체중 변화에 이미 반영되어 매주 소비량 계산에 들어가요.';

  @override
  String weekWorkouts(String n) {
    return '운동 $n회';
  }

  @override
  String get workoutSuggestTitle => '운동 횟수를 맞춰볼까요?';

  @override
  String workoutSuggestBody(String strength, String cardio, String planned) {
    return '지난 2주 동안 주 평균 근력 $strength회 · 유산소 $cardio회 운동했어요. 설정은 주 $planned회예요. 실제 기록에 맞추면 공식 추정치가 더 정확해져요.';
  }

  @override
  String get workoutSuggestApply => '기록에 맞추기';

  @override
  String get workoutSuggestApplied => '운동 횟수를 업데이트했어요';

  @override
  String get settingsTitle => '설정';

  @override
  String get sectionProfile => '내 정보';

  @override
  String profileSummary(String sex, String age, String height) {
    return '$sex · $age세 · ${height}cm';
  }

  @override
  String get editGoal => '목표 다시 설정';

  @override
  String get editGoalDesc => '기록은 그대로 두고 목표만 바꿔요';

  @override
  String get sectionApp => '앱';

  @override
  String get language => '언어';

  @override
  String get langSystem => '시스템 설정';

  @override
  String get checkinDay => '체크인 요일';

  @override
  String get notifications => '체크인 알림';

  @override
  String get notificationsDesc => '모바일 앱에서 지원 예정';

  @override
  String get units => '단위';

  @override
  String get sectionData => '데이터';

  @override
  String get demoData => '샘플 데이터 채우기';

  @override
  String get demoDataDesc => '5주치 예시 기록으로 체크인과 그래프를 체험해요';

  @override
  String get demoConfirm => '지금 기록이 샘플 데이터로 바뀌어요. 계속할까요?';

  @override
  String get demoLoaded => '샘플 데이터를 채웠어요. 체크인 탭을 확인해 보세요!';

  @override
  String consentGiven(String date) {
    return '민감정보 저장 동의일: $date';
  }

  @override
  String get deleteAll => '모든 데이터 삭제';

  @override
  String get deleteAllConfirm =>
      '체중, 식사, 목표 기록이 모두 지워지고 처음 화면으로 돌아가요. 되돌릴 수 없어요.';

  @override
  String get sectionAbout => '정보';

  @override
  String get version => '버전';

  @override
  String get savedMealsManage => '내 식사 관리';
}
