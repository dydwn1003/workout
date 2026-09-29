// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class LKo extends L {
  LKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => '알아서핏';

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
  String get chartHint => '그래프를 누르거나 좌우로 밀면 날짜별 기록을 볼 수 있어요';

  @override
  String get tipWeight => '체중';

  @override
  String get tipTrend => '추세';

  @override
  String get tipIntake => '섭취';

  @override
  String get tipWorkout => '운동';

  @override
  String get tipNone => '기록 없음';

  @override
  String tipMinutes(String n) {
    return '$n분';
  }

  @override
  String get sugar => '당류';

  @override
  String sugarOfLimit(String g, String limit) {
    return '$g / 최대 ${limit}g';
  }

  @override
  String sugarUnknownMeals(String n) {
    return '당류 정보가 없는 기록 $n개는 빠져 있어요';
  }

  @override
  String sugarPer(String g) {
    return '당류 ${g}g';
  }

  @override
  String get sugarNone => '당류 정보 없음';

  @override
  String get satFat => '포화지방';

  @override
  String satFatUnknownMeals(String n) {
    return '포화지방 정보가 없는 기록 $n개는 빠져 있어요';
  }

  @override
  String satFatPer(String g) {
    return '포화지방 ${g}g';
  }

  @override
  String get satFatNone => '포화지방 정보 없음';

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
  String get bodyFat => '체지방률';

  @override
  String get smm => '골격근량';

  @override
  String compSince(String date) {
    return '$date보다';
  }

  @override
  String get compRecent => '최근 측정';

  @override
  String get weightDeleted => '체중 기록을 지웠어요';

  @override
  String showAllN(String n) {
    return '전체 보기 ($n)';
  }

  @override
  String get showLess => '접기';

  @override
  String get noWeights => '아직 체중 기록이 없어요. 오른쪽 위 + 로 기록해 보세요.';

  @override
  String get weightRowHint => '눌러서 수정 · 옆으로 밀어서 삭제';

  @override
  String get workoutWeeklyGoal => '주간 목표 달성';

  @override
  String workoutGoalValue(String done, String goal) {
    return '$done/$goal회';
  }

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
  String get usageAnalytics => '사용 데이터 보내기';

  @override
  String get usageAnalyticsDesc =>
      '어떤 기능을 쓰는지만 익명으로 보내 앱 개선에 써요. 체중·식사 같은 건강 정보는 보내지 않아요.';

  @override
  String get privacyPolicy => '개인정보처리방침';

  @override
  String get signInNotice =>
      '로그인하면 체중·식사 같은 건강 정보가 기기 간 동기화를 위해 서버에 저장돼요. 계정을 삭제하면 바로 지워져요.';

  @override
  String get sectionAccount => '계정';

  @override
  String get signInTitle => '로그인하고 기록 지키기';

  @override
  String get signInBody => '로그인하면 기록이 계정에 저장돼서 폰을 바꾸거나 여러 기기에서 써도 그대로 이어져요.';

  @override
  String get signInCta => '로그인하고 동기화';

  @override
  String get signInApple => 'Apple로 계속하기';

  @override
  String get signInGoogle => 'Google로 계속하기';

  @override
  String get signInKakao => '카카오로 계속하기';

  @override
  String get signInFailed => '로그인하지 못했어요. 다시 시도해 주세요.';

  @override
  String get signInUnavailable => '이 빌드에서는 로그인을 쓸 수 없어요.';

  @override
  String get haveAccount => '이미 계정이 있어요 · 로그인해서 불러오기';

  @override
  String get syncing => '동기화 중…';

  @override
  String syncedAt(String time) {
    return '$time에 동기화됨';
  }

  @override
  String get syncFailed => '동기화하지 못했어요. 연결되면 다시 시도할게요.';

  @override
  String get syncNow => '지금 동기화';

  @override
  String get signOut => '로그아웃';

  @override
  String get signOutConfirm =>
      '로그아웃하면 이 기기의 기록은 지워져요. 계정에는 그대로 있어서 다시 로그인하면 불러와요.';

  @override
  String get deleteAccount => '계정 삭제';

  @override
  String get deleteAccountConfirm => '계정과 모든 기록을 영구적으로 삭제할까요? 되돌릴 수 없어요.';

  @override
  String streakTitle(String days) {
    return '연속 $days일째 기록 중!';
  }

  @override
  String get streakZero => '오늘 첫 기록으로 연속 기록을 시작해요';

  @override
  String get pickDate => '날짜 선택';

  @override
  String get logCalendarTitle => '기록 달력';

  @override
  String logCalendarDays(String logged, String total) {
    return '$logged/$total일 기록';
  }

  @override
  String logCurrentStreak(String days) {
    return '지금 $days일 연속';
  }

  @override
  String logLongestStreak(String days) {
    return '최장 $days일 연속';
  }

  @override
  String logMissedDays(String days) {
    return '놓친 날 $days일';
  }

  @override
  String get logLegendDone => '기록함';

  @override
  String get logLegendMissed => '놓침';

  @override
  String get logLegendToday => '오늘';

  @override
  String get logCalendarHint =>
      '식사·체중·운동 중 하나라도 기록한 날은 체크, 기록이 없던 날은 X로 표시돼요. 날짜를 누르면 그날로 이동해요.';

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
  String get searchAgain => '다시 검색';

  @override
  String get updateAvailable => '새 버전이 나왔어요';

  @override
  String get reload => '새로고침';

  @override
  String get updateInStore => '새 버전이 나왔어요. 스토어에서 업데이트해 주세요';

  @override
  String get updateStoreAction => '업데이트';

  @override
  String get pressBackAgainToExit => '한 번 더 누르면 앱이 닫혀요';

  @override
  String get replaceMeal => '다른 음식으로 바꾸기';

  @override
  String mealReplaced(String name) {
    return '$name(으)로 바꿨어요';
  }

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
  String get workoutTrendTitle => '운동 추이';

  @override
  String get statusDietBreak => '쉬어가기';

  @override
  String get stallTitle => '체중이 3주째 거의 그대로예요';

  @override
  String get stallBody => '정체기는 누구에게나 와요. 세 가지 중 하나를 골라 보세요.';

  @override
  String get stallCheckLogs => '① 기록 점검하기';

  @override
  String get stallCheckLogsBody =>
      '소스·음료·간식이 빠지면 실제보다 적게 먹은 걸로 계산돼요. 목표의 60%도 안 되는 날:';

  @override
  String get stallNoSuspicious => '최근 2주에 의심되는 날은 없어요. 기록은 잘 되고 있어요.';

  @override
  String stallLower(String kcal) {
    return '② 목표를 $kcal kcal로 낮추기';
  }

  @override
  String stallBreak(String kcal) {
    return '③ 1~2주 쉬어가기 (유지 칼로리 $kcal kcal)';
  }

  @override
  String get stallBreakBody =>
      '잠깐 유지 칼로리로 먹으면 몸과 마음이 회복돼서, 다시 시작할 때 더 잘 빠지는 경우가 많아요. 끝나면 원래 계획으로 돌아가요.';

  @override
  String breakWeeks(String n) {
    return '$n주 쉬기';
  }

  @override
  String breakActive(String date) {
    return '쉬어가는 중 · $date까지 유지 칼로리로 드세요';
  }

  @override
  String breakStarted(String date) {
    return '$date까지 쉬어가요. 체크인은 그다음에 해요.';
  }

  @override
  String get goalReachedTitle => '목표 체중에 도달했어요! 🎉';

  @override
  String get goalReachedBody =>
      '정말 수고 많으셨어요. 이제 이 체중을 지키는 유지 모드로 바꿔 볼까요? 목표 칼로리를 소비량에 맞춰 드릴게요.';

  @override
  String get goalReachedMaintain => '유지 모드로 바꾸기';

  @override
  String get goalReachedLater => '나중에';

  @override
  String maintainStarted(String kcal) {
    return '유지 모드로 바꿨어요. 목표는 $kcal kcal예요.';
  }

  @override
  String get notifDay1Title => '오늘 기록 잊지 않으셨죠?';

  @override
  String get notifDay1Body => '대충이라도 괜찮아요. 한 끼만 넣어도 추정이 정확해져요.';

  @override
  String get notifDay3Title => '3일 쉬셨네요';

  @override
  String get notifDay3Body => '오늘 한 끼만 기록해도 추세가 다시 이어져요.';

  @override
  String get notifDay7Title => '일주일 만이에요';

  @override
  String get notifDay7Body => '체중만 재도 코칭이 다시 시작돼요.';

  @override
  String get notifDay14Title => '다시 시작해 볼까요?';

  @override
  String get notifDay14Body => '목표 칼로리를 지금 몸에 맞게 다시 맞춰 드릴게요.';

  @override
  String get notifDay21Title => '3주째 쉬고 계시네요';

  @override
  String get notifDay21Body => '완벽하지 않아도 돼요. 오늘 한 끼부터 다시 시작해 봐요.';

  @override
  String get notifDay28Title => '한 달이 됐어요';

  @override
  String get notifDay28Body => '지금 체중 한 번만 재 주시면, 거기서부터 다시 맞춰 드릴게요.';

  @override
  String get notifLong1Title => '알아서핏이 기다리고 있어요';

  @override
  String get notifLong1Body => '언제든 돌아오시면 거기서부터 다시 맞춰 드려요.';

  @override
  String get notifLong2Title => '체중만 재 볼까요?';

  @override
  String get notifLong2Body => '기록 없이 체중만 넣어도 추세를 다시 이어 갈 수 있어요.';

  @override
  String get notifLong3Title => '새로 시작하기 좋은 날이에요';

  @override
  String get notifLong3Body => '목표를 지금 모습에 맞게 다시 세워 드릴게요.';

  @override
  String get notifCheckinTitle => '오늘은 체크인 날이에요';

  @override
  String get notifCheckinBody => '지난주 기록으로 이번 주 목표를 맞춰 드릴게요.';

  @override
  String get remindersOffer =>
      '기록을 쉬면 살짝 알려 드릴까요? 첫 한 달은 일주일에 한 번, 그 뒤로는 2주에 한 번이에요. 설정에서 언제든 끌 수 있어요.';

  @override
  String get remindersYes => '알려 주세요';

  @override
  String get remindersNo => '괜찮아요';

  @override
  String get remindersTitle => '기록·체크인 알림';

  @override
  String get remindersDesc =>
      '기록을 쉬면 1·3일째, 첫 한 달은 매주, 그 뒤로는 2주마다, 체크인 날에도 저녁 8시에 알려 드려요';

  @override
  String get remindersOnMsg => '알림을 켰어요';

  @override
  String get remindersDenied =>
      '알림이 꺼져 있어요. 휴대폰 설정 → 애플리케이션 → 알아서핏 → 알림을 켠 뒤 다시 켜 주세요';

  @override
  String get remindersUnsupported => '알림은 앱에서 받을 수 있어요';

  @override
  String get reviewTitle => '알아서핏 어떠세요?';

  @override
  String get reviewGood => '좋아요';

  @override
  String get reviewBad => '아쉬워요';

  @override
  String get reviewThanks => '고마워요! 큰 힘이 돼요';

  @override
  String get reviewAskStore => '스토어에 별점을 남겨 주시면 더 많은 분이 알아서핏을 만날 수 있어요.';

  @override
  String get reviewRate => '별점 남기기';

  @override
  String get reviewLater => '다음에';

  @override
  String get reviewBadTitle => '무엇이 아쉬웠나요?';

  @override
  String get reviewBadHint => '불편했던 점을 알려 주시면 고쳐 볼게요';

  @override
  String get reviewSend => '보내기';

  @override
  String get reviewSent => '의견 고마워요. 꼭 참고할게요';

  @override
  String get reportTitle => '이번 주 코칭 리포트';

  @override
  String get reportAte => '먹은 양';

  @override
  String reportAteValue(String days, String kcal) {
    return '최근 $days일 평균 $kcal kcal';
  }

  @override
  String get reportTrend => '체중 추세';

  @override
  String reportTrendValue(String delta, String bal, String dir) {
    return '${delta}kg → 하루 $bal kcal $dir';
  }

  @override
  String get reportDeficit => '부족';

  @override
  String get reportSurplus => '남음';

  @override
  String get reportObserved => '실제 소비량';

  @override
  String reportObservedValue(
    String intake,
    String sign,
    String bal,
    String obs,
  ) {
    return '$intake $sign $bal ≈ $obs kcal';
  }

  @override
  String get reportEstimate => '추정 소비량';

  @override
  String reportEstimateValue(String formula, String prev, String est) {
    return '공식 추정 $formula와 섞고, 한 주 변화는 ±150 kcal까지만: $prev → $est kcal';
  }

  @override
  String get reportTarget => '새 목표';

  @override
  String reportTargetValue(String est, String gap, String target, String kg) {
    return '소비량 $est − $gap = $target kcal (주 ${kg}kg 페이스)';
  }

  @override
  String reportTargetSurplus(String est, String gap, String target, String kg) {
    return '소비량 $est + $gap = $target kcal (주 ${kg}kg 페이스)';
  }

  @override
  String reportNoObserved(String formula) {
    return '아직 기록이 2주가 안 돼서 공식으로 소비량을 $formula kcal로 추정했어요. 기록이 쌓이면 실제 데이터로 바뀌어요.';
  }

  @override
  String get swapsTitle => '가볍게 바꿔 볼까요?';

  @override
  String get swapsDesc =>
      '최근 4주에 자주 드신 음식과 같은 종류 중에서, 1회분 칼로리가 적고 단백질은 비슷한 음식이에요.';

  @override
  String swapTimes(String n) {
    return '$n번 드심';
  }

  @override
  String swapSaves(String kcal) {
    return '1회분 $kcal kcal 적어요';
  }

  @override
  String swapSavesSugar(String kcal, String sugar) {
    return '1회분 $kcal kcal · 당류 ${sugar}g 적어요';
  }

  @override
  String get patternsTitle => '최근 4주 식사 패턴';

  @override
  String patternWeekend(String kcal) {
    return '주말에 평일보다 하루 평균 $kcal kcal 더 드세요. 주말 한 끼만 미리 정해 두면 차이가 확 줄어요.';
  }

  @override
  String patternSnack(String pct, String food) {
    return '간식이 전체 칼로리의 $pct%예요. 가장 많이 드신 간식은 \'$food\'예요. 양을 반으로 줄이거나 단백질 간식으로 바꿔 보세요.';
  }

  @override
  String patternSkipBreakfast(String kcal) {
    return '아침을 거른 날은 하루에 $kcal kcal 더 드시는 편이에요. 가벼운 아침(계란·요거트)이 오히려 도움이 될 수 있어요.';
  }

  @override
  String get focusTitle => '다음 주 한 가지';

  @override
  String focusLogMore(String n) {
    return '식사를 5일 이상 기록해 주세요 (이번 주 $n일). 그래야 소비량을 제대로 계산할 수 있어요.';
  }

  @override
  String focusWeighMore(String n) {
    return '체중을 주 3회 이상 재 주세요 (이번 주 $n회). 아침 공복에 재면 가장 정확해요.';
  }

  @override
  String focusKeepTarget(String kcal) {
    return '평균이 목표보다 $kcal kcal 많았어요. 목표를 더 낮추기보다 지금 목표를 지키는 게 먼저예요.';
  }

  @override
  String focusMoreProtein(String g, String target) {
    return '단백질이 하루 평균 ${g}g이에요 (목표 ${target}g). 끼니마다 단백질 한 가지씩 더해 보세요.';
  }

  @override
  String get focusKeepGoing => '기록도 식사도 잘 지키고 있어요. 이번 주도 지금처럼만 하면 돼요!';

  @override
  String get tipMissedYesterday =>
      '어제 식사 기록이 비어 있어요. 기억나는 만큼만 넣어도 소비량 추정이 훨씬 정확해져요.';

  @override
  String tipOverKcal(String kcal) {
    return '오늘은 목표보다 $kcal kcal 더 드셨어요. 괜찮아요, 중요한 건 한 주 평균이에요. 내일 평소대로 드시면 충분해요.';
  }

  @override
  String tipOverSugar(String g) {
    return '당류가 한도보다 ${g}g 많아요. 단 음료나 디저트 하나만 바꿔도 금방 줄어요.';
  }

  @override
  String tipOverSatFat(String g) {
    return '포화지방이 한도보다 ${g}g 많아요. 튀김·가공육·크림 대신 구이나 살코기를 골라 보세요.';
  }

  @override
  String tipProteinLeft(String g, String food, String grams) {
    return '단백질이 ${g}g 남았어요. $food ${grams}g이면 대부분 채워져요.';
  }

  @override
  String tipProteinLeftPlain(String g) {
    return '단백질이 ${g}g 남았어요. 남은 식사에 고기·생선·두부·계란을 넣어 보세요.';
  }

  @override
  String tipLowKcalLeft(String kcal) {
    return '남은 칼로리가 $kcal kcal예요. 저녁은 채소와 단백질 위주로 가볍게 드셔 보세요.';
  }

  @override
  String tipMorningPlan(String kcal, String g) {
    return '오늘 목표는 $kcal kcal, 단백질 ${g}g이에요. 끼니마다 단백질부터 챙겨 보세요.';
  }

  @override
  String get tipOnTrack => '지금까지 목표 안에서 잘 드시고 있어요. 이대로면 충분해요!';

  @override
  String get intakeTrendTitle => '섭취 칼로리';

  @override
  String get intakeAvg => '평균 섭취';

  @override
  String get intakeAvgTarget => '평균 목표';

  @override
  String get intakeLoggedDays => '기록한 날';

  @override
  String get intakeLegend => '섭취';

  @override
  String get intakeTarget => '목표';

  @override
  String get intakeNotLogged => '기록 없음';

  @override
  String get intakeTapHint => '막대를 누르면 그날 섭취량을 볼 수 있어요 (평균은 기록한 날만)';

  @override
  String get workoutThisWeek => '최근 7일';

  @override
  String workoutThisWeekValue(String n, String minutes) {
    return '$n회 · $minutes분';
  }

  @override
  String get workoutAvg4w => '4주 평균';

  @override
  String workoutAvgValue(String n) {
    return '주 $n회';
  }

  @override
  String get legendPlanned => '설정 횟수';

  @override
  String get noWorkoutData => '운동을 기록하면 주별 추이를 볼 수 있어요';

  @override
  String tipRest(String days) {
    return '$days일 연속 운동했어요! 회복도 운동의 일부예요. 하루쯤 쉬어도 괜찮아요.';
  }

  @override
  String tipStrengthForLoss(String target, String days) {
    return '감량 중엔 근력운동을 주 $target일 이상 하면 근육을 지키는 데 도움이 돼요. (최근 7일 $days일)';
  }

  @override
  String tipMoreThanUsual(String minutes) {
    return '최근 3주 평균보다 $minutes분 더 운동했어요!';
  }

  @override
  String tipLessThanUsual(String minutes) {
    return '최근 3주 평균보다 $minutes분 적어요. 바쁜 한 주였다면 짧게라도 괜찮아요.';
  }

  @override
  String tipPlanDone(String sessions) {
    return '이번 주 목표 $sessions회를 채웠어요!';
  }

  @override
  String tipPlanRemaining(String planned, String left) {
    return '주 $planned회 목표까지 $left회 남았어요.';
  }

  @override
  String tipCardioDone(String minutes) {
    return '유산소 $minutes분으로 WHO 권장량(주 150분)을 채웠어요!';
  }

  @override
  String tipCardioProgress(String minutes, String left) {
    return '유산소 $minutes분 · WHO 권장량(주 150분)까지 $left분 남았어요.';
  }

  @override
  String get workoutFeedbackTitle => '이번 주 운동 피드백';

  @override
  String get minutesField => '분';

  @override
  String get slotBreakfast => '아침';

  @override
  String get slotLunch => '점심';

  @override
  String get slotDinner => '저녁';

  @override
  String get slotSnack => '간식';

  @override
  String get tabSearch => '검색';

  @override
  String get searchHint => '음식 검색 (예: 닭가슴살, 신라면)';

  @override
  String get recentFoodsChip => '최근';

  @override
  String addMealToSlot(String slot) {
    return '$slot 기록';
  }

  @override
  String get recentSearches => '최근 검색';

  @override
  String get clearAll => '전체 삭제';

  @override
  String macroSummary(String p, String c, String f) {
    return '단백질 ${p}g · 탄수화물 ${c}g · 지방 ${f}g';
  }

  @override
  String get noRecentFoods => '검색해서 기록한 음식이 여기에 모여요';

  @override
  String noResults(String query) {
    return '\'$query\' 검색 결과가 없어요';
  }

  @override
  String get remoteSearching => '전체 식품 DB(약 30만 개)에서 더 찾는 중…';

  @override
  String get remoteSearchFailed => '전체 식품 DB에 연결하지 못했어요. 앱에 있는 음식만 보여요.';

  @override
  String remoteResults(String n) {
    return '전체 식품 DB에서 $n개 더';
  }

  @override
  String get createFood => '내 음식 만들기';

  @override
  String get createFoodDesc => '찾는 음식이 없으면 직접 만들어 저장해요';

  @override
  String get foodMacrosEstimatedNote =>
      '\'추정\'(~)은 업체가 공개하지 않은 값을 비슷한 음식의 영양정보로 계산한 거예요.';

  @override
  String get estimated => '추정';

  @override
  String get foodRefNote => '영양정보는 일반적인 참고값이에요. 제품·조리법에 따라 다를 수 있어요.';

  @override
  String get unitLabel => '단위';

  @override
  String get quantity => '수량';

  @override
  String addToSlot(String slot) {
    return '$slot에 추가';
  }

  @override
  String removeFromSlot(String slot) {
    return '$slot에서 빼기';
  }

  @override
  String get removeShort => '빼기';

  @override
  String get pickSlot => '어떤 끼니를 기록할까요?';

  @override
  String updateInSlot(String slot) {
    return '$slot 기록 수정하기';
  }

  @override
  String addedCount(String n) {
    return '$n개 추가됨';
  }

  @override
  String get done => '완료';

  @override
  String get foodName => '음식 이름';

  @override
  String get servingLabel => '1회 제공 단위';

  @override
  String get servingGrams => '중량 g (선택)';

  @override
  String get perServing => '1회 제공량 기준 영양정보';

  @override
  String customSaved(String name) {
    return '\'$name\'을(를) 내 음식에 저장했어요';
  }

  @override
  String get photoSoonShort => '사진 분석은 곧 제공돼요';

  @override
  String get mealSlotLabel => '끼니';

  @override
  String addedToSlot(String name, String slot) {
    return '$name → $slot';
  }

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
  String browseMore(String count) {
    return '이 분류에는 $count개가 있어요. 이름으로 검색해 보세요.';
  }

  @override
  String get foodDataSource => '출처: 식품의약품안전처 식품영양성분 데이터베이스';

  @override
  String get foodDataSourceDesc =>
      '음식 검색의 영양정보는 공공데이터포털에서 받은 데이터를 100g 기준으로 바꾼 값이에요.';

  @override
  String get savedMealsManage => '내 식사 관리';
}
