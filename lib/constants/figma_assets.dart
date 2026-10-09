class FigmaAssets {
  static const _home = 'assets/figma/home';
  static const _homeBeginner = '$_home/beginner';
  static const _auth = 'assets/figma/auth';
  static const _quiz = 'assets/figma/quiz';
  static const _quizStreak = '$_quiz/streak';
  static const _quizReward = '$_quiz/reward';
  static const _shop = 'assets/figma/shop';
  static const _calendar = 'assets/figma/calendar';
  static const _friends = 'assets/figma/friends';
  static const _settings = 'assets/figma/settings';
  static const _iconsAuth = 'assets/icons/auth';
  static const _onboarding = 'assets/figma/onboarding';
  static const _iconsOnboarding = 'assets/icons/onboarding';

  // Home
  static const hamsterMain = '$_home/hamster_main.png';
  static const homeBagLeft = '$_home/bag_left.svg';
  static const homeBagRight = '$_home/bag_right.svg';
  static const homeStar = '$_home/star.svg';
  static const homeSparkle = '$_home/sparkle.svg';

  /// 홈 카드·썸네일 — 단일 햄스터만 (`assets/images/hamster_auth.png`)
  static const hamsterCard = hamsterAuth;
  static const bgTop = '$_home/bg_top.svg';
  static const bgBottom = '$_home/bg_bottom.svg';
  static const menuIcon = '$_home/menu_icon.svg';
  static const megaphone = '$_home/megaphone.svg';
  static const chevronRight = '$_home/chevron_right.svg';
  static const chevronSmall = '$_home/chevron_small.svg';
  static const chevronLearning = '$_home/chevron_learning.svg';
  static const statEnergy = '$_home/stat_energy.svg';
  static const statCoin = '$_home/stat_coin.svg';
  static const statStreak = '$_home/stat_streak.svg';
  static const cardHamsterFrame = '$_home/card_hamster_frame.svg';
  static const bookmark = '$_home/bookmark.svg';
  static const questIconCircle = '$_home/quest_icon_circle.svg';
  static const questIconDot = '$_home/quest_icon_dot.svg';
  static const navList = '$_home/nav_list.svg';
  static const navHomeA = '$_home/nav_home_a.svg';
  static const navHomeB = '$_home/nav_home_b.svg';
  static const navProfile = '$_home/nav_profile.svg';

  // 홈 단계 오각형 — 티어마다 모양이 같고 색만 달라 한 벌을 색 필터로 칠한다.
  static const homeStagePentagonSmall = '$_home/stage_pentagon_small.svg';
  static const homeStagePentagonLarge = '$_home/stage_pentagon_large.svg';

  // 초급·중급 홈 햄스터 (Figma `541:2666` / `541:2676`) — 구멍 밖으로 고개를 내민 모습.
  static const homeHamsterPeekBody = '$_home/hamster_peek_body.svg';
  static const homeHamsterPeekBelly = '$_home/hamster_peek_belly.svg';
  static const homeHamsterPeekBottom = '$_home/hamster_peek_bottom.svg';
  static const homeHamsterPeekPawLeft = '$_home/hamster_peek_paw_left.svg';
  static const homeHamsterPeekPawRight = '$_home/hamster_peek_paw_right.svg';

  // 복습 집 햄스터 아이콘 — 티어 공통.
  static const homeReviewHouseIcon = '$_home/review_house_icon.svg';

  /// 복습 집에 도착한 햄핀이 레이어 (Figma `526:2236`~`526:2269`, 티어 공통분).
  static String homeReviewArrivalLayer(int index) =>
      '$_home/review_arrival/layer_${index.toString().padLeft(2, '0')}.svg';

  // Home beginner (131:5278)
  static const homePathMap = '$_homeBeginner/path_map.svg';
  static const homeEllipse154 = '$_homeBeginner/ellipse_154.svg';
  static const homeEllipse155 = '$_homeBeginner/ellipse_155.svg';
  static const homeNode1 = '$_homeBeginner/node_1.png';
  static const homeNode3 = '$_homeBeginner/node_3.png';
  static const homeBeginnerMegaphone = '$_homeBeginner/megaphone.svg';
  static const homeBeginnerChevronNews = '$_homeBeginner/chevron_news.svg';
  static const homeBeginnerChevronLearning =
      '$_homeBeginner/chevron_learning.svg';
  static const homeBeginnerLearningQ = '$_homeBeginner/learning_q.svg';
  static const homeBeginnerMenuIcon = '$_homeBeginner/menu_icon.svg';
  static const homeBeginnerStatEnergy = '$_homeBeginner/stat_energy.svg';
  static const homeBeginnerStatCoin = '$_homeBeginner/stat_coin.svg';
  static const homeBeginnerStatStreak = '$_homeBeginner/stat_streak.svg';

  // 하단 탭 아이콘 — 선택된 탭만 파란색, 나머지는 회색 (뉴스화면 579:2230,
  // 홈화면_초급 526:2699, 마이페이지 538:56).
  static const tabNewsOn = '$_home/tab_news_on.svg';
  static const tabNewsOff = '$_home/tab_news_off.svg';
  static const tabHomeOn = '$_home/tab_home_on.svg';
  static const tabHomeOff = '$_home/tab_home_off.svg';
  static const tabMyOn = '$_home/tab_my_on.svg';
  static const tabMyOff = '$_home/tab_my_off.svg';

  // Auth — 벡터 SVG는 assets/icons/, PNG는 assets/figma/auth/
  static const authDividerLine = '$_iconsAuth/divider_line.svg';
  static const authDividerLineSignup = '$_iconsAuth/divider_line_signup.svg';
  static const googleLogin = '$_auth/google.png';
  static const appleLogin = '$_auth/apple.png';
  static const kakaoLogin = '$_auth/kakao.png';
  static const googleSignup = '$_auth/google_signup.png';
  static const appleSignup = '$_auth/apple_signup.png';
  static const kakaoSignup = '$_auth/kakao_signup.png';

  // 온보딩 (Figma `👀 9.6 화면작업중`) — 스플래시·초기 화면·가입 단계
  static const onboardingSplash = '$_onboarding/splash.png';
  static const onboardingHamsterIntro = '$_onboarding/hamster_intro.svg';
  static const onboardingHamsterBubble = '$_onboarding/hamster_bubble.svg';
  static const onboardingKakao = '$_onboarding/kakao.png';
  static const onboardingBackArrow = '$_iconsOnboarding/back_arrow.svg';
  static const onboardingClearMark = '$_iconsOnboarding/clear_mark.svg';
  static const onboardingEye = '$_iconsOnboarding/eye.svg';
  static const onboardingEyeOff = '$_iconsOnboarding/eye_off.svg';
  static const onboardingCheckMark = '$_iconsOnboarding/check_mark.svg';
  static const onboardingCheckSmall = '$_iconsOnboarding/check_small.svg';
  static const onboardingChevron = '$_iconsOnboarding/chevron.svg';
  static const onboardingIntroDot = '$_iconsOnboarding/intro_dot.svg';

  // Shop
  static const shopSeedPouch = '$_shop/seed_pouch.svg';
  // Figma `675:454` 아이템 상점창 배너 일러스트.
  static const shopBannerCloset = '$_shop/banner_closet.png';
  static const shopBannerFloor = '$_shop/banner_floor.png';
  static const shopBannerStump = '$_shop/banner_stump.png';
  static const shopBannerPhotoPink = '$_shop/banner_photo_pink.png';
  static const shopBannerPhotoBlue = '$_shop/banner_photo_blue.png';
  static const shopBannerChevronGreen = '$_shop/banner_chevron_green.svg';
  static const shopBannerChevronWood = '$_shop/banner_chevron_wood.svg';

  // Calendar
  static const calendarPeekHamster = '$_calendar/hamster_peek.png';
  static const calendarDropOn = '$_calendar/drop_empty_1.svg';
  static const calendarDropMid = '$_calendar/drop_empty_2.svg';
  static const calendarDropOff = '$_calendar/drop_filled.svg';
  static const calendarPodium1 = '$_calendar/podium_1.svg';
  static const calendarPodium2 = '$_calendar/podium_2.svg';
  static const calendarPodium3 = '$_calendar/podium_3.svg';
  static const calendarPodium4 = '$_calendar/podium_4.svg';
  static const calendarTodayHamster = '$_calendar/today_hamster.svg';

  // Friends (node 270:9)
  static const friendsBackChevron = '$_friends/back_chevron.svg';
  static const friendsSearchIcon = '$_friends/search_icon.svg';
  static const friendsHeroHamster = '$_friends/hero_hamster.svg';

  // Settings — 마이페이지 수정 (273:181)
  /// 흰 원 + 햄스터 + 카메라 배지 (Group 466, 161×161).
  static const settingsProfile = '$_settings/profile_group.svg';
  static const settingsChevron = '$_settings/chevron.svg';
  static const settingsChevronSmall = '$_settings/chevron_small.svg';
  static const settingsPlus = '$_settings/plus_small.svg';

  /// 학습 과정 카드의 불꽃 (Group 82, 32×43) — 위에 현재 단계 숫자를 얹는다.
  static const settingsStageFlame = '$_settings/stage_flame.svg';

  /// 학습 과정 시트의 곰 모양 단계 칩 (Group 556, 67×47) — colorFilter로 칠한다.
  static const settingsStageBear = '$_settings/stage_bear.svg';

  // Quiz (Figma `137:5521` 퀴즈._객_문제)
  static const quizSpeechBubble = '$_quiz/speech_bubble.svg';
  static const quizBackChevronQuestion = '$_quiz/back_chevron_question.svg';
  static const quizQuestionIcon = '$_quiz/q_icon.svg';
  static const quizCharacter = '$_quiz/character_group_502.svg';
  static const quizCharacterShadow = '$_quiz/character_shadow.svg';
  static const quizExplainBox = '$_quiz/explain_box.svg';

  // 객관식 긴 질문 박스 (Figma `632:1090` 문제 / `632:1182` 정답).
  static const quizQuestionBox = '$_quiz/question_box.svg';
  static const quizQuestionBoxAnswer = '$_quiz/question_box_answer.svg';

  // 객관식 코인 장식 — 햄핀이 옆(짧은 질문) / 박스 아래(긴 질문·해설).
  static const quizCoin = '$_quiz/coin.svg';
  static const quizCoinMark = '$_quiz/coin_mark.svg';
  static const quizCoinStack = '$_quiz/coin_stack.svg';
  static const quizCoinShadowSmall = '$_quiz/coin_shadow_small.svg';
  static const quizCoinShadowMedium = '$_quiz/coin_shadow_medium.svg';
  static const quizCoinShadowLarge = '$_quiz/coin_shadow_large.svg';
  static const quizBoxCoin = '$_quiz/box_coin.svg';
  static const quizBoxCoinSmall = '$_quiz/box_coin_small.svg';
  static const quizBoxCoinStack = '$_quiz/box_coin_stack.svg';
  static const quizBoxCoinShadow = '$_quiz/box_coin_shadow.svg';
  static const quizQuestionIconExplain = '$_quiz/q_icon_explain.svg';

  // OX 퀴즈 (Figma `137:5890` 퀴즈_ox) — Q 아이콘은 4지선다와 같은 에셋을 쓴다.
  static const quizOxBackChevron = '$_quiz/ox_back_chevron.svg';
  static const quizOxCharacter = '$_quiz/ox_character.svg';
  static const quizOxCharacterExplain = '$_quiz/ox_character_explain.svg';
  static const quizOxCharacterShadow = '$_quiz/ox_character_shadow.svg';

  // OX 햄핀이 양옆 코인 장식 (Figma `639:2963` Group 630/631·Ellipse 231).
  static const quizOxCoin = '$_quiz/ox_coin.svg';
  static const quizOxCoinStack = '$_quiz/ox_coin_stack.svg';
  static const quizOxCoinShadow = '$_quiz/ox_coin_shadow.svg';
  static const quizOxMarkO = '$_quiz/ox_mark_o.svg';
  static const quizOxMarkX = '$_quiz/ox_mark_x.svg';

  // 퀴즈_중간 학습창 (293:1649)
  static const quizStreakCircleOuter = '$_quizStreak/circle_outer.svg';
  static const quizStreakCircleInner = '$_quizStreak/circle_inner.svg';
  static const quizStreakRayHub = '$_quizStreak/ray_hub.svg';
  static const quizStreakSparkleBlue = '$_quizStreak/sparkle_blue.svg';
  static const quizStreakSparkleWhite = '$_quizStreak/sparkle_white.svg';
  static const quizStreakCloud = '$_quizStreak/cloud.svg';
  static const quizStreakHamster = '$_quizStreak/hamster.svg';

  // 퀴즈_결과보기창 (131:3546) — 씨앗·에너지 아이콘은 홈과 같은 것을 쓴다.
  static const quizRewardHamster = '$_quizReward/hamster.svg';
  static const quizRewardHamsterShadow = '$_quizReward/hamster_shadow.svg';
  static const quizRewardStatCorrect = '$_quizReward/stat_correct.svg';
  static const quizRewardSparkle = '$_quizReward/sparkle.svg';

  // 단일 햄스터 PNG (손 흔드는 캐릭터)
  static const hamsterAuth = 'assets/images/hamster_auth.png';
}
