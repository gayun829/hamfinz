import '../models/quiz_question.dart';

class QuizData {
  static const int dailyQuestionCount = 10;
  static const int correctXp = 10;
  static const int wrongXp = 2;

  /// 정답 1개당 지급하는 해바라기씨.
  static const int seedsPerCorrect = 5;

  /// 에너지 최대치. 하루가 바뀌면 이 값으로 회복한다.
  static const int maxEnergy = 100;

  /// 문제 1개 풀 때 소모하는 에너지. (잠정 — 변동 가능)
  static const int energyCostPerQuestion = 5;

  /// 한 학습 세션(10문제) 시작에 필요한 에너지.
  static const int sessionEnergyCost =
      dailyQuestionCount * energyCostPerQuestion;

  static final List<QuizQuestion> allQuestions = [
    const QuizQuestion(
      id: 'q1',
      type: QuizType.ox,
      category: QuizCategory.allowance,
      question: '용돈을 받으면 전부 소비해도 괜찮다.',
      options: ['O', 'X'],
      correctIndex: 1,
      explanation: '용돈은 수입과 지출을 계획하는 연습의 기회입니다. 일정 비율은 저축하는 습관이 중요합니다.',
    ),
    const QuizQuestion(
      id: 'q2',
      type: QuizType.multipleChoice,
      category: QuizCategory.allowance,
      question: '월 용돈 30만원 중 고정 지출(교통·식비)을 먼저 빼고 남은 금액을 관리하는 방식은?',
      options: ['제로베이스 예산', '50-30-20 법칙', '무계획 소비', '카드 할부 우선'],
      correctIndex: 1,
      explanation: '50-30-20 법칙은 필수 지출·생활비·저축/투자를 나누는 실용적인 방법입니다.',
    ),
    const QuizQuestion(
      id: 'q3',
      type: QuizType.ox,
      category: QuizCategory.saving,
      question: '비상금은 3~6개월치 생활비 정도를 목표로 모으는 것이 일반적이다.',
      options: ['O', 'X'],
      correctIndex: 0,
      explanation: '예상치 못한 상황에 대비해 3~6개월치 생활비를 비상금으로 준비하는 것이 권장됩니다.',
    ),
    const QuizQuestion(
      id: 'q4',
      type: QuizType.multipleChoice,
      category: QuizCategory.saving,
      question: '적금과 예금의 차이로 가장 적절한 설명은?',
      options: [
        '적금은 일정 기간 납입, 예금은 한 번에 예치',
        '적금은 금리가 항상 더 낮다',
        '예금은 자동이체가 불가능하다',
        '둘 다 세금이 없다',
      ],
      correctIndex: 0,
      explanation: '적금은 정기 납입 방식, 예금은 목돈 예치 방식이 일반적입니다.',
    ),
    const QuizQuestion(
      id: 'q5',
      type: QuizType.ox,
      category: QuizCategory.stock,
      question: '주식은 원금 보장이 되는 투자 상품이다.',
      options: ['O', 'X'],
      correctIndex: 1,
      explanation: '주식은 가격 변동으로 손실 가능성이 있어 원금 보장이 되지 않습니다.',
    ),
    const QuizQuestion(
      id: 'q6',
      type: QuizType.multipleChoice,
      category: QuizCategory.stock,
      question: '주식 투자 초보자가 먼저 이해해야 할 개념은?',
      options: ['공매도', '분산 투자', '레버리지 ETF', '파생상품'],
      correctIndex: 1,
      explanation: '분산 투자는 한 종목에 몰빵하지 않고 리스크를 나누는 기본 원칙입니다.',
    ),
    const QuizQuestion(
      id: 'q7',
      type: QuizType.ox,
      category: QuizCategory.insurance,
      question: '보험은 위험을 전가해 예기치 못한 손실을 줄이는 수단이다.',
      options: ['O', 'X'],
      correctIndex: 0,
      explanation: '보험은 보험료를 내고 큰 손실 위험을 보험사와 나누는 금융 도구입니다.',
    ),
    const QuizQuestion(
      id: 'q8',
      type: QuizType.multipleChoice,
      category: QuizCategory.insurance,
      question: '20대가 우선 검토할 보험 유형으로 적절한 것은?',
      options: ['변액연금', '실손의료보험', '종신보험 위주', '변액유니버셜'],
      correctIndex: 1,
      explanation: '실손의료보험은 의료비 부담을 줄이는 기본적인 보장으로 많이 가입합니다.',
    ),
    const QuizQuestion(
      id: 'q9',
      type: QuizType.ox,
      category: QuizCategory.tax,
      question: '아르바이트 소득도 연말정산 대상이 될 수 있다.',
      options: ['O', 'X'],
      correctIndex: 0,
      explanation: '근로소득이 있으면 연말정산을 통해 납부세액을 정산할 수 있습니다.',
    ),
    const QuizQuestion(
      id: 'q10',
      type: QuizType.multipleChoice,
      category: QuizCategory.tax,
      question: '소득세 절감을 위해 활용할 수 있는 항목은?',
      options: ['현금 영수증/카드 공제', '무조건 면세', '세금 미납', '가계부 미작성'],
      correctIndex: 0,
      explanation: '신용카드·체크카드·현금영수증 사용액은 소득공제 등 혜택 대상이 될 수 있습니다.',
    ),
    const QuizQuestion(
      id: 'q11',
      type: QuizType.ox,
      category: QuizCategory.credit,
      question: '신용카드 연체는 신용점수에 부정적 영향을 줄 수 있다.',
      options: ['O', 'X'],
      correctIndex: 0,
      explanation: '연체 기록은 신용평가에 반영되어 대출·카드 이용에 불리할 수 있습니다.',
    ),
    const QuizQuestion(
      id: 'q12',
      type: QuizType.multipleChoice,
      category: QuizCategory.credit,
      question: '신용점수를 관리하는 좋은 습관은?',
      options: [
        '대출·카드값 기한 내 상환',
        '한도를 항상 100% 사용',
        '여러 곳에 동시에 대출 신청',
        '연체 후 무시하기',
      ],
      correctIndex: 0,
      explanation: '기한 내 상환은 신용관리의 기본이며, 이용률 관리도 중요합니다.',
    ),
    const QuizQuestion(
      id: 'q13',
      type: QuizType.multipleChoice,
      category: QuizCategory.allowance,
      question: '용돈 기록을 꾸준히 하면 좋은 점은?',
      options: [
        '소비 패턴을 파악할 수 있다',
        '용돈이 자동으로 늘어난다',
        '세금이 면제된다',
        '카드 한도가 올라간다',
      ],
      correctIndex: 0,
      explanation: '가계부·기록 습관은 어디에 쓰는지 보며 예산을 조절하는 데 도움이 됩니다.',
    ),
    const QuizQuestion(
      id: 'q14',
      type: QuizType.ox,
      category: QuizCategory.saving,
      question: '복리 이자는 이자에도 이자가 붙는 구조이다.',
      options: ['O', 'X'],
      correctIndex: 0,
      explanation: '복리는 원금뿐 아니라 쌓인 이자에도 이자가 적용되어 장기 저축·투자에서 차이가 큽니다.',
    ),
    const QuizQuestion(
      id: 'q15',
      type: QuizType.multipleChoice,
      category: QuizCategory.insurance,
      question: '보험 가입 전 꼭 확인해야 할 것은?',
      options: [
        '보장 내용과 면책·해지 조건',
        '보험사 로고 색깔',
        '지인 추천만으로 가입',
        '보험료만 보고 즉시 가입',
      ],
      correctIndex: 0,
      explanation: '무엇이 보장되는지, 어떤 경우 보장되지 않는지 약관을 확인하는 것이 중요합니다.',
    ),
  ];

  static List<QuizQuestion> dailyQuestions([DateTime? date]) {
    final seed = (date ?? DateTime.now()).day + (date ?? DateTime.now()).month * 31;
    final sorted = List<QuizQuestion>.from(allQuestions)
      ..sort((a, b) => (a.id.hashCode + seed).compareTo(b.id.hashCode + seed));
    return sorted.take(dailyQuestionCount).toList();
  }
}
