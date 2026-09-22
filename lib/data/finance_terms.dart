/// 금융 용어 사전.
///
/// 두 가지로 쓴다.
/// 1. **뉴스 목록 필터** — 구글뉴스 비즈니스 헤드라인에는 기업 인사·수출 실적·
///    부동산 시황처럼 학습 소재가 안 되는 기사가 섞여 있어서, 제목에 이 표의
///    용어가 없으면 목록에서 뺀다.
/// 2. **뉴스 용어 퀴즈** — RSS는 본문을 안 준다. 그래서 기사를 시험 보지 않고,
///    제목에서 잡은 용어 하나를 3지선다 한 문제로 묻고 해설로 가르친다.
///
/// 설명·문제가 붙은 용어만 학습으로 이어진다([FinanceTerm.hasLesson]).
/// 나머지는 필터로만 쓰인다 — 자주 걸리는 용어부터 채워 나가면 된다.
library;

/// 용어 하나에 붙는 3지선다 한 문제.
///
/// 뉴스 퀴즈 화면(Figma `뉴스_퀴즈창`)은 문제 하나에 보기 셋이다. 기사를 읽다
/// 곁다리로 보는 거라 한 문제로 끝내고, 맞히면 씨앗을 조금 준다.
class TermQuiz {
  const TermQuiz({
    required this.question,
    required this.options,
    required this.answer,
    required this.why,
  });

  final String question;

  /// 보기 3개. 한 줄에 들어가게 짧게 쓴다.
  final List<String> options;

  /// 정답 보기의 인덱스.
  final int answer;

  /// 해설 화면에 띄울 한두 줄. 틀린 이유가 여기서 끝나야 한다.
  final String why;
}

class FinanceTerm {
  const FinanceTerm({
    required this.term,
    required this.categoryId,
    this.summary = '',
    this.forMe = '',
    this.quiz,
  });

  final String term;

  /// `kInterestCategories`의 id. 목록의 용어 줄 이모지와 퀴즈 카테고리에 쓴다.
  final String categoryId;

  /// 한 줄 정의.
  final String summary;

  /// '나한테는?' — 사전적 정의 말고 내 지갑에 뭐가 달라지는지.
  final String forMe;

  /// 3지선다 한 문제. 없으면 학습으로 안 이어진다.
  final TermQuiz? quiz;

  /// 퀴즈를 띄울 수 있는 용어인지. 설명과 문제가 다 있어야 한다.
  bool get hasLesson => summary.isNotEmpty && quiz != null;
}

/// 실제 기사 제목에 등장하는지 확인하고 추린 목록.
/// (구글뉴스 비즈니스 헤드라인 70건 기준 약 20%가 걸린다 — TOP 10을 채우는 수준)
const List<FinanceTerm> kFinanceTerms = [
  // 저축&예금
  FinanceTerm(
    term: '기준금리',
    categoryId: 'saving',
    summary: '한국은행이 정하는, 나라 전체 금리의 기준이 되는 금리.',
    forMe: '기준금리가 오르면 내 대출 이자가 늘고, 예금 이자도 같이 오른다.',
    quiz: TermQuiz(
      question: '기준금리를 정하는 곳은?',
      options: [
        '한국은행',
        '각 시중은행',
        '기획재정부',
      ],
      answer: 0,
      why: '한국은행 금융통화위원회가 나라에 하나로 정한다. 은행마다 다른 건 그 위에 붙는 예금·대출 금리다.',
    ),
  ),
  FinanceTerm(
    term: '예금금리',
    categoryId: 'saving',
    summary: '은행이 예금에 붙여 주는 금리.',
    forMe: '같은 돈을 맡겨도 은행마다 달라서, 비교만 해도 이자가 늘어난다.',
    quiz: TermQuiz(
      question: '예금금리가 오르면 돈을 맡긴 사람은 어떻게 될까?',
      options: [
        '받는 이자가 늘어난다',
        '받는 이자가 줄어든다',
        '달라지지 않는다',
      ],
      answer: 0,
      why: '예금금리는 은행이 나에게 주는 값이다. 내가 내는 쪽은 대출금리다.',
    ),
  ),
  FinanceTerm(
    term: '정기예금',
    categoryId: 'saving',
    summary: '목돈을 정해진 기간 맡기고 만기에 이자를 받는 예금.',
    forMe: '기간을 약속하는 대신 수시입출금 통장보다 금리가 훨씬 높다.',
    quiz: TermQuiz(
      question: '정기예금을 만기 전에 해지하면 어떻게 될까?',
      options: [
        '약속한 금리를 그대로 받는다',
        '훨씬 낮은 중도해지 금리를 받는다',
        '원금이 깎인다',
      ],
      answer: 1,
      why: '원금은 그대로 돌려받지만 금리가 중도해지 금리로 깎인다. 만기를 채우는 게 이자의 대부분이다.',
    ),
  ),
  FinanceTerm(
    term: '적금',
    categoryId: 'saving',
    summary: '매달 정해진 돈을 나눠 넣어 만기에 목돈으로 받는 저축.',
    forMe: '용돈에서 매달 조금씩 떼어 두는 습관을 만들기에 좋다.',
    quiz: TermQuiz(
      question: '연 5% 적금에 매달 10만 원씩 1년 넣으면 실제 받는 이자는?',
      options: [
        '넣은 돈 전체의 5%인 6만 원',
        '그 절반쯤인 3만 원 남짓',
        '만기 전엔 이자가 없다',
      ],
      answer: 1,
      why: '첫 달 넣은 돈만 12개월치 이자를 받고 마지막 달 돈은 한 달치만 받는다. 실제로 손에 쥐는 이자는 절반쯤이다.',
    ),
  ),
  FinanceTerm(
    term: '예금',
    categoryId: 'saving',
    summary: '은행에 돈을 맡기고 이자를 받는 것. 목돈을 한 번에 넣어 두는 쪽이다.',
    forMe: '당장 안 쓸 목돈은 그냥 통장에 두는 것보다 이자가 붙는다.',
    quiz: TermQuiz(
      question: '다음 중 맡긴 원금이 줄어들 수 있는 것은?',
      options: [
        '정기예금',
        '주식',
        '적금',
      ],
      answer: 1,
      why: '예금·적금은 원금이 보장된다. 원금이 줄 수 있는 건 주식·펀드처럼 투자하는 상품이다.',
    ),
  ),
  FinanceTerm(term: '수신', categoryId: 'saving'),
  FinanceTerm(
    term: '고금리',
    categoryId: 'saving',
    summary: '금리가 전반적으로 높은 상황.',
    forMe: '예금 이자는 반갑지만, 대출이 있으면 갚는 돈이 커진다.',
    quiz: TermQuiz(
      question: '고금리 시기에 부담이 가장 커지는 사람은?',
      options: [
        '예금만 갖고 있는 사람',
        '변동금리 대출이 있는 사람',
        '현금만 들고 있는 사람',
      ],
      answer: 1,
      why: '변동금리는 시장 금리를 따라 움직인다. 고금리 시기엔 매달 갚는 이자가 바로 늘어난다.',
    ),
  ),
  FinanceTerm(
    term: '조달금리',
    categoryId: 'saving',
    summary: '은행이 빌려줄 돈을 구해 올 때 내는 금리.',
    forMe: '조달금리가 오르면 내 대출금리도 뒤따라 오른다.',
    quiz: TermQuiz(
      question: '은행 조달금리가 오르면 보통 어떻게 될까?',
      options: [
        '대출금리가 따라 오른다',
        '대출금리가 내려간다',
        '대출금리와는 상관없다',
      ],
      answer: 0,
      why: '은행도 돈을 빌려 와서 빌려준다. 구해 오는 값이 비싸지면 그만큼 대출금리에 얹는다.',
    ),
  ),
  FinanceTerm(
    term: '금리',
    categoryId: 'saving',
    summary: '돈을 빌려 쓴 값. 원금에 몇 %를 더 주고받는지를 말한다.',
    forMe: '예금 금리는 내가 받는 돈, 대출 금리는 내가 내는 돈이다.',
    quiz: TermQuiz(
      question: '같은 1,000만 원을 빌릴 때 총 이자가 가장 적은 경우는?',
      options: [
        '금리 5%, 3년',
        '금리 3%, 5년',
        '금리 3%, 3년',
      ],
      answer: 2,
      why: '이자는 원금 × 금리 × 기간이다. 금리가 낮고 기간이 짧을수록 총 이자가 적다.',
    ),
  ),
  FinanceTerm(
    term: '이자',
    categoryId: 'saving',
    summary: '돈을 맡기거나 빌린 값으로 주고받는 돈.',
    forMe: '예금에 붙으면 내가 받고, 대출에 붙으면 내가 낸다.',
    quiz: TermQuiz(
      question: '100만 원을 연 3% 예금에 1년 넣으면 이자는 얼마일까?',
      options: [
        '3천 원',
        '3만 원',
        '30만 원',
      ],
      answer: 1,
      why: '100만 원의 3%는 3만 원이다. 여기서 이자소득세를 떼고 실제로는 2만 5천 원쯤 들어온다.',
    ),
  ),

  // 신용
  FinanceTerm(
    term: '주택담보대출',
    categoryId: 'credit',
    summary: '집을 담보로 잡히고 받는 대출. 줄여서 주담대라고 부른다.',
    forMe: '담보가 있어 금리가 낮은 대신, 못 갚으면 그 집이 넘어간다.',
    quiz: TermQuiz(
      question: '주택담보대출 금리가 신용대출보다 보통 낮은 이유는?',
      options: [
        '빌리는 금액이 커서',
        '집이 담보라 은행이 떼일 위험이 작아서',
        '정부가 이자를 일부 내줘서',
      ],
      answer: 1,
      why: '못 갚아도 은행이 집을 팔아 회수할 수 있어 떼일 위험이 작기 때문이다. 다만 LTV 규제가 있어 집값 전액을 빌릴 수는 없다.',
    ),
  ),
  FinanceTerm(term: '주담대', categoryId: 'credit'),
  FinanceTerm(term: '전세대출', categoryId: 'credit'),
  FinanceTerm(term: '가계대출', categoryId: 'credit'),
  FinanceTerm(term: '신용대출', categoryId: 'credit'),
  FinanceTerm(
    term: '대출금리',
    categoryId: 'credit',
    summary: '돈을 빌릴 때 내는 금리. 고정금리와 변동금리가 있다.',
    forMe: '고정은 계약할 때 값에 묶이고, 변동은 시장 금리에 따라 바뀐다.',
    quiz: TermQuiz(
      question: '앞으로 금리가 오를 것 같을 때 유리한 쪽은?',
      options: [
        '고정금리',
        '변동금리',
        '둘이 똑같다',
      ],
      answer: 0,
      why: '고정금리는 계약할 때 값에 묶여서 오르는 국면에 유리하다. 내리는 국면에서는 변동금리가 유리하다.',
    ),
  ),
  FinanceTerm(
    term: '신용점수',
    categoryId: 'credit',
    summary: '돈을 잘 갚을 사람인지를 1~1000점으로 매긴 값.',
    forMe: '점수가 높으면 같은 대출도 더 낮은 금리로 받는다.',
    quiz: TermQuiz(
      question: '신용점수를 떨어뜨리는 행동은?',
      options: [
        '적금에 가입한다',
        '카드를 아예 안 쓴다',
        '카드값을 며칠 늦게 낸다',
      ],
      answer: 2,
      why: '약속한 날짜에 갚았는지가 가장 크게 반영된다. 짧은 연체도 기록에 남는다. 카드를 아예 안 쓰면 떨어지진 않지만 갚은 기록이 없어 점수도 잘 안 오른다.',
    ),
  ),
  FinanceTerm(
    term: '대출',
    categoryId: 'credit',
    summary: '은행에서 돈을 빌리고 원금과 이자를 나눠 갚는 것.',
    forMe: '갚는 돈은 원금 + 이자다. 빌린 액수보다 항상 많이 나간다.',
    quiz: TermQuiz(
      question: '대출 원금을 빨리 갚으면 어떻게 될까?',
      options: [
        '내가 내는 총 이자가 줄어든다',
        '총 이자는 그대로다',
        '신용점수가 떨어진다',
      ],
      answer: 0,
      why: '이자는 남아 있는 원금에만 붙는다. 원금이 줄면 그 다음 달 이자도 같이 준다.',
    ),
  ),
  FinanceTerm(
    term: '연체',
    categoryId: 'credit',
    summary: '갚기로 한 날짜를 넘겨 못 갚는 것.',
    forMe: '며칠만 늦어도 기록이 남고, 다음 대출 금리가 올라간다.',
    quiz: TermQuiz(
      question: '카드값을 5일 늦게 냈다. 어떻게 될까?',
      options: [
        '아무 일도 없다',
        '연체 기록이 남고 신용점수가 떨어진다',
        '다음 달에 몰아서 내면 된다',
      ],
      answer: 1,
      why: '짧은 연체도 기록에 남고 연체이자가 붙는다. 점수가 떨어지면 다음에 빌릴 때 금리가 올라간다.',
    ),
  ),
  FinanceTerm(
    term: '차주',
    categoryId: 'credit',
    summary: '돈을 빌린 사람. 뉴스에서 대출받은 쪽을 가리킬 때 쓴다.',
    forMe: '「취약차주」는 갚을 능력이 약해진 대출자를 말한다.',
    quiz: TermQuiz(
      question: '뉴스에 나오는 「차주」는 누구를 말할까?',
      options: [
        '돈을 빌려준 은행',
        '돈을 빌린 사람',
        '대출을 중개한 사람',
      ],
      answer: 1,
      why: '빌릴 차(借) + 주인 주(主), 빚을 진 사람이다. 빌려준 쪽은 채권자라고 한다.',
    ),
  ),

  // 주식&투자
  FinanceTerm(
    term: '코스피',
    categoryId: 'stock',
    summary: '유가증권시장에 상장된 회사들의 주가를 묶어 만든 한국 대표 주가지수.',
    forMe: '코스피가 올랐다는 건 한국 대표 기업들 주가가 대체로 올랐다는 뜻이다.',
    quiz: TermQuiz(
      question: '\'코스피가 올랐다\'는 말의 뜻은?',
      options: [
        '삼성전자 주가가 올랐다',
        '내가 가진 종목이 다 올랐다',
        '상장 회사들 주가가 대체로 올랐다',
      ],
      answer: 2,
      why: '코스피는 유가증권시장에 상장된 회사 전체를 묶어 만든 지수라 시장 전체의 온도계다. 평균이라서 지수가 올라도 내 종목은 내렸을 수 있다.',
    ),
  ),
  FinanceTerm(
    term: '코스닥',
    categoryId: 'stock',
    summary: '중소·벤처기업이 주로 상장된 한국의 또 다른 주식시장.',
    forMe: '코스피보다 회사가 작아서 주가가 더 크게 오르내린다.',
    quiz: TermQuiz(
      question: '코스닥이 코스피와 다른 점은?',
      options: [
        '중소·벤처기업이 주로 상장돼 있다',
        '국채만 거래한다',
        '해외 주식만 거래한다',
      ],
      answer: 0,
      why: '성장하는 중소·벤처기업을 위해 따로 만든 시장이다. 회사 규모가 작아 변동도 크다.',
    ),
  ),
  FinanceTerm(term: '공모주', categoryId: 'stock'),
  FinanceTerm(
    term: '증시',
    categoryId: 'stock',
    summary: '주식이 사고팔리는 시장을 통틀어 부르는 말.',
    forMe: '뉴스의 "증시가 좋다"는 주식 시장 분위기 전반을 말한다.',
    quiz: TermQuiz(
      question: '한국 증시의 정규 거래 시간은?',
      options: [
        '24시간 언제나',
        '평일 오전 9시 ~ 오후 3시 30분',
        '평일 오전 9시 ~ 오후 6시',
      ],
      answer: 1,
      why: '정규 거래는 평일 오전 9시부터 오후 3시 30분까지다. 그 앞뒤로 시간외 거래가 조금 있을 뿐이다.',
    ),
  ),
  FinanceTerm(
    term: '주가',
    categoryId: 'stock',
    summary: '주식 한 주의 값.',
    forMe: '주가 × 주식 수가 그 회사의 시장 가치(시가총액)다.',
    quiz: TermQuiz(
      question: '주가가 올랐다면 그 회사가 지금 돈을 잘 번다는 뜻일까?',
      options: [
        '그렇다',
        '아니다, 앞으로 잘될 거라는 기대만으로도 오른다',
        '주가와 실적은 아무 상관이 없다',
      ],
      answer: 1,
      why: '주가는 미래 기대까지 미리 반영한다. 그래서 적자 회사 주가가 오르기도, 돈 잘 버는 회사 주가가 내리기도 한다.',
    ),
  ),
  FinanceTerm(
    term: '배당',
    categoryId: 'stock',
    summary: '회사가 번 돈의 일부를 주주에게 나눠 주는 것.',
    forMe: '주식을 들고만 있어도 받는 돈이다. 다만 회사가 안 줄 수도 있다.',
    quiz: TermQuiz(
      question: '배당은 언제 받을 수 있을까?',
      options: [
        '주식을 사면 매달 받는다',
        '회사가 주기로 정했을 때 받는다',
        '주식을 팔 때만 받는다',
      ],
      answer: 1,
      why: '배당은 의무가 아니다. 회사가 이익을 다시 투자하기로 하면 안 줄 수도 있다.',
    ),
  ),
  FinanceTerm(
    term: '펀드',
    categoryId: 'stock',
    summary: '여러 사람 돈을 모아 전문가가 대신 굴려 주는 상품.',
    forMe: '종목을 직접 안 골라도 되지만 운용보수를 떼인다.',
    quiz: TermQuiz(
      question: '펀드가 ETF와 다른 점은?',
      options: [
        '하루 한 번 정해진 기준가로 정산된다',
        '원금이 보장된다',
        '세금을 안 낸다',
      ],
      answer: 0,
      why: 'ETF는 장중에 실시간으로 사고팔지만 펀드는 하루 한 번 정산된다. 둘 다 원금 보장은 아니다.',
    ),
  ),
  FinanceTerm(
    term: 'ETF',
    categoryId: 'stock',
    summary: '여러 종목을 한 바구니에 담아, 주식처럼 사고파는 상품.',
    forMe: '한 주만 사도 수십~수백 개 회사에 나눠 투자한 셈이 된다.',
    quiz: TermQuiz(
      question: 'ETF가 일반 펀드와 다른 점은?',
      options: [
        '장중에 주식처럼 실시간으로 사고판다',
        '원금이 보장된다',
        '한 회사에만 투자한다',
      ],
      answer: 0,
      why: '펀드는 하루 한 번 정해진 값으로 정산되지만 ETF는 시장이 열려 있는 동안 실시간으로 거래된다. 여러 종목에 나눠 담아도 시장이 내리면 같이 내려서 원금 보장은 아니다.',
    ),
  ),
  FinanceTerm(
    term: '국채',
    categoryId: 'stock',
    summary: '나라가 돈을 빌리면서 발행하는 빚 문서. 사 두면 정해진 이자를 받는다.',
    forMe: '국채 금리는 예금·대출 금리가 따라 움직이는 기준선 노릇을 한다.',
    quiz: TermQuiz(
      question: '국채 금리가 오르면 이미 갖고 있던 국채의 가격은?',
      options: [
        '올라간다',
        '변하지 않는다',
        '내려간다',
      ],
      answer: 2,
      why: '금리와 채권 가격은 반대로 움직인다. 새로 나온 채권이 이자를 더 주면, 이자가 적은 옛 채권은 값을 깎아야 팔린다.',
    ),
  ),
  FinanceTerm(term: '상장', categoryId: 'stock'),

  // 세금
  FinanceTerm(
    term: '소득공제',
    categoryId: 'tax',
    summary: '세금을 매기는 기준 소득에서 일정 금액을 빼 주는 것.',
    forMe: '기준 소득이 줄어드니 내야 할 세금도 줄어든다.',
    quiz: TermQuiz(
      question: '소득공제와 세액공제의 차이는?',
      options: [
        '소득공제는 기준 소득을 깎고, 세액공제는 세금 자체를 깎는다',
        '둘은 같은 말이다',
        '소득공제는 직장인만, 세액공제는 사업자만 받는다',
      ],
      answer: 0,
      why: '소득공제는 세금을 계산하기 전 소득을 줄이고, 세액공제는 계산된 세금에서 바로 뺀다.',
    ),
  ),
  FinanceTerm(term: '세액공제', categoryId: 'tax'),
  FinanceTerm(
    term: '연말정산',
    categoryId: 'tax',
    summary: '한 해 동안 미리 뗀 세금을 다시 계산해, 더 내거나 돌려받는 절차.',
    forMe: '쓴 돈을 증명하면 이미 낸 세금 일부가 통장으로 돌아온다.',
    quiz: TermQuiz(
      question: '연말정산에 대한 설명으로 맞는 것은?',
      options: [
        '항상 세금을 돌려받는다',
        '세금을 더 내야 할 수도 있다',
        '프리랜서도 같이 한다',
      ],
      answer: 1,
      why: '미리 뗀 돈이 실제 세금보다 적었으면 그만큼 더 낸다. 프리랜서·사업자는 이듬해 5월 종합소득세로 따로 신고한다.',
    ),
  ),
  FinanceTerm(term: '원천징수', categoryId: 'tax'),
  FinanceTerm(
    term: '종합소득세',
    categoryId: 'tax',
    summary: '한 해 동안 여러 곳에서 번 소득을 합쳐 매기는 세금.',
    forMe: '알바·프리랜서·부업 소득이 있으면 5월에 직접 신고해야 한다.',
    quiz: TermQuiz(
      question: '종합소득세는 언제 신고할까?',
      options: [
        '이듬해 1~2월',
        '이듬해 5월',
        '그해 12월',
      ],
      answer: 1,
      why: '전년도 소득을 이듬해 5월에 신고·납부한다. 근로소득만 있으면 연말정산으로 끝나서 따로 안 한다.',
    ),
  ),
  FinanceTerm(term: '비과세', categoryId: 'tax'),
  FinanceTerm(term: '과세', categoryId: 'tax'),
  FinanceTerm(
    term: '세금',
    categoryId: 'tax',
    summary: '나라가 살림에 쓰려고 국민에게서 걷는 돈.',
    forMe: '월급쟁이는 월급에서 미리 떼고(원천징수), 연말정산으로 정산한다.',
    quiz: TermQuiz(
      question: '물건값에 이미 포함돼 있는 세금은?',
      options: [
        '부가가치세',
        '소득세',
        '재산세',
      ],
      answer: 0,
      why: '값에 이미 10%가 포함돼 있다. 가게가 대신 받아 나라에 낼 뿐, 내는 사람은 나다. 알바로 번 돈에는 소득세가 붙는다.',
    ),
  ),

  // 보험
  FinanceTerm(
    term: '실손보험',
    categoryId: 'insurance',
    summary: '병원비에서 실제로 쓴 돈을 보장해 주는 보험.',
    forMe: '건강보험이 안 대주는 진료비 일부를 메워 준다.',
    quiz: TermQuiz(
      question: '실손보험은 병원비를 어떻게 보장할까?',
      options: [
        '정해진 금액을 무조건 준다',
        '실제로 낸 돈에서 자기부담금을 뺀 만큼 준다',
        '병원비 전액을 다 준다',
      ],
      answer: 1,
      why: '이름 그대로 실제 손해를 보장한다. 자기부담금이 있어 전액은 안 나온다.',
    ),
  ),
  FinanceTerm(term: '자동차보험', categoryId: 'insurance'),
  FinanceTerm(term: '연금보험', categoryId: 'insurance'),
  FinanceTerm(
    term: '보험료',
    categoryId: 'insurance',
    summary: '보험에 가입해 매달(또는 매년) 내는 돈.',
    forMe: '보험료가 싸면 보장도 같이 얇아진다. 값만 보고 고르면 안 된다.',
    quiz: TermQuiz(
      question: '같은 병을 보장하는데 보험료가 더 싸다면 그 이유로 맞는 것은?',
      options: [
        '내가 직접 내야 하는 자기부담금이 더 크다',
        '보험사가 손해를 보고 판다',
        '정부가 차액을 대준다',
      ],
      answer: 0,
      why: '보장 범위·한도·자기부담금이 다르면 보험료가 달라진다. 싼 만큼 내가 물어야 하는 몫이 크다.',
    ),
  ),
  FinanceTerm(
    term: '보험',
    categoryId: 'insurance',
    summary: '여럿이 조금씩 돈을 모아 두었다가, 사고를 당한 사람에게 몰아 주는 제도.',
    forMe: '평소엔 나가기만 하는 돈이지만, 큰 병이나 사고 한 번을 막아 준다.',
    quiz: TermQuiz(
      question: '보장성 보험에서 사고가 안 났을 때 낸 보험료는?',
      options: [
        '전액 돌려받는다',
        '이자를 붙여 돌려받는다',
        '대부분 돌려받지 못한다',
      ],
      answer: 2,
      why: '그 돈이 사고를 당한 사람에게 갔기 때문이다. 만기에 돌려주는 저축성 보험은 그만큼 보험료가 비싸다.',
    ),
  ),

  // 용돈&지출 — 물가·환율은 거시 지표지만 생활비에 바로 닿아서 이쪽에 둔다.
  FinanceTerm(
    term: '소비자물가',
    categoryId: 'allowance',
    summary: '사람들이 자주 사는 물건·서비스 값을 모아 만든 대표 물가 지표.',
    forMe: '뉴스의 "물가 3% 상승"은 거의 이 지표를 말한다.',
    quiz: TermQuiz(
      question: '소비자물가에 들어가지 않는 것은?',
      options: [
        '식료품 값',
        '아파트 매매가격',
        '월세',
      ],
      answer: 1,
      why: '집을 사는 건 소비가 아니라 자산 거래라 빠진다. 대신 월세 같은 주거비가 들어간다.',
    ),
  ),
  FinanceTerm(
    term: '인플레이션',
    categoryId: 'allowance',
    summary: '물가가 전반적으로 계속 오르는 현상.',
    forMe: '가만히 둔 현금은 인플레이션만큼 매년 힘이 빠진다.',
    quiz: TermQuiz(
      question: '인플레이션을 잡으려고 중앙은행이 보통 하는 일은?',
      options: [
        '금리를 올린다',
        '금리를 내린다',
        '돈을 더 찍는다',
      ],
      answer: 0,
      why: '금리를 올려 빌리고 쓰는 걸 줄이게 만들어 물가를 누른다. 가만히 둔 현금은 인플레이션만큼 매년 힘이 빠진다.',
    ),
  ),
  FinanceTerm(term: '생활비', categoryId: 'allowance'),
  FinanceTerm(
    term: '물가',
    categoryId: 'allowance',
    summary: '물건과 서비스 값을 전체적으로 묶어 본 수준.',
    forMe: '물가가 오르면 같은 용돈으로 살 수 있는 게 줄어든다.',
    quiz: TermQuiz(
      question: '물가 상승률이 3%에서 1%로 낮아졌다. 물건값은?',
      options: [
        '내려갔다',
        '그대로다',
        '여전히 오르는 중이다',
      ],
      answer: 2,
      why: '오르는 속도가 느려진 것뿐이고 값은 여전히 오르는 중이다. 실제로 내리려면 상승률이 마이너스여야 한다.',
    ),
  ),
  FinanceTerm(
    term: '환율',
    categoryId: 'allowance',
    summary: '우리 돈과 외국 돈을 바꾸는 비율. 보통 1달러가 몇 원인지로 본다.',
    forMe: '환율이 오르면 해외 직구와 여행 비용이 그만큼 비싸진다.',
    quiz: TermQuiz(
      question: '원/달러 환율이 1,300원에서 1,400원이 되면?',
      options: [
        '원화 가치가 떨어진 것이다',
        '원화 가치가 오른 것이다',
        '수입 물건값이 싸진다',
      ],
      answer: 0,
      why: '같은 1달러를 사는 데 원화를 더 줘야 하기 때문이다. 수입할 때도 원화를 더 줘야 해서 기름·밀가루처럼 수입에 기대는 품목부터 값이 오른다.',
    ),
  ),
  FinanceTerm(term: '용돈', categoryId: 'allowance'),
  FinanceTerm(
    term: '연금',
    categoryId: 'allowance',
    summary: '일할 때 모아 두었다가 나이 들어 매달 나눠 받는 돈.',
    forMe: '국민연금 말고 퇴직연금·개인연금이 더 있고, 개인연금은 세액공제를 받는다.',
    quiz: TermQuiz(
      question: '국민연금 보험료는 어떻게 내나?',
      options: [
        '매년 한 번 직접 낸다',
        '월급에서 자동으로 빠져나간다',
        '회사가 전액 낸다',
      ],
      answer: 1,
      why: '회사가 절반을 같이 내고, 내 몫은 월급에서 미리 뗀다. 받을 때는 이름 그대로 매달 나눠 받는 게 기본이다.',
    ),
  ),
];

/// 제목에서 용어를 찾는다. 없으면 null.
///
/// 규칙 두 개.
/// 1. 가장 **긴** 용어 — '주택담보대출'이 걸렸는데 '대출'로 가르치면 어긋난다.
/// 2. 길이가 같으면 제목에서 **먼저 나온** 용어.
///
/// 2번이 없으면 선언 순서가 승자를 정해버린다. `금리`가 사전 맨 앞에 있어서
/// 「미국 국채금리 급등」처럼 2글자끼리 붙은 제목을 전부 금리로 끌어갔다.
/// 실측으로 연합뉴스 TOP 10 중 6건이 금리였고 그중 3건이 이 동점 탓이었다.
FinanceTerm? matchFinanceTerm(String title) {
  FinanceTerm? best;
  var bestAt = -1;
  for (final candidate in kFinanceTerms) {
    final at = title.indexOf(candidate.term);
    if (at < 0) continue;
    if (best == null ||
        candidate.term.length > best.term.length ||
        (candidate.term.length == best.term.length && at < bestAt)) {
      best = candidate;
      bestAt = at;
    }
  }
  return best;
}
