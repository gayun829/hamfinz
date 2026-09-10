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
  FinanceTerm(term: '예금금리', categoryId: 'saving'),
  FinanceTerm(term: '정기예금', categoryId: 'saving'),
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
  FinanceTerm(term: '이자', categoryId: 'saving'),

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
  FinanceTerm(term: '연체', categoryId: 'credit'),
  FinanceTerm(term: '차주', categoryId: 'credit'),

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
  FinanceTerm(term: '코스닥', categoryId: 'stock'),
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
  FinanceTerm(term: '주가', categoryId: 'stock'),
  FinanceTerm(term: '배당', categoryId: 'stock'),
  FinanceTerm(term: '펀드', categoryId: 'stock'),
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
  FinanceTerm(term: '소득공제', categoryId: 'tax'),
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
  FinanceTerm(term: '종합소득세', categoryId: 'tax'),
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
  FinanceTerm(term: '실손보험', categoryId: 'insurance'),
  FinanceTerm(term: '자동차보험', categoryId: 'insurance'),
  FinanceTerm(term: '연금보험', categoryId: 'insurance'),
  FinanceTerm(term: '보험료', categoryId: 'insurance'),
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
/// 가장 **긴** 용어를 고른다 — '주택담보대출'이 걸렸는데 '대출'로 가르치면
/// 기사와 어긋나기 때문이다.
FinanceTerm? matchFinanceTerm(String title) {
  FinanceTerm? best;
  for (final candidate in kFinanceTerms) {
    if (!title.contains(candidate.term)) continue;
    if (best == null || candidate.term.length > best.term.length) {
      best = candidate;
    }
  }
  return best;
}
