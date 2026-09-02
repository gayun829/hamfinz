/// 금융 용어 사전.
///
/// 두 가지로 쓴다.
/// 1. **뉴스 목록 필터** — 구글뉴스 비즈니스 헤드라인에는 기업 인사·수출 실적·
///    부동산 시황처럼 학습 소재가 안 되는 기사가 섞여 있어서, 제목에 이 표의
///    용어가 없으면 목록에서 뺀다.
/// 2. **뉴스 용어 학습** — 기사 본문은 못 읽는다(구글뉴스 링크가 리다이렉트다).
///    그래서 기사를 시험 보지 않고, 제목에서 잡은 용어 하나를 가르치고 그걸 묻는다.
///
/// 설명·문제가 붙은 용어만 학습으로 이어진다([FinanceTerm.hasLesson]).
/// 나머지는 필터로만 쓰인다 — 자주 걸리는 용어부터 채워 나가면 된다.
library;

/// 용어 하나에 붙는 OX 문제.
class TermOx {
  const TermOx({
    required this.statement,
    required this.answer,
    required this.why,
  });

  /// O/X로 답할 문장.
  final String statement;

  /// 참이면 O.
  final bool answer;

  /// 채점 뒤 보여줄 한두 줄 해설. 틀린 이유가 여기서 끝나야 한다.
  final String why;
}

class FinanceTerm {
  const FinanceTerm({
    required this.term,
    required this.categoryId,
    this.summary = '',
    this.forMe = '',
    this.quiz = const [],
  });

  final String term;

  /// `kInterestCategories`의 id. 목록의 용어 줄 이모지와 퀴즈 카테고리에 쓴다.
  final String categoryId;

  /// 한 줄 정의.
  final String summary;

  /// '나한테는?' — 사전적 정의 말고 내 지갑에 뭐가 달라지는지.
  final String forMe;

  /// OX 2문제. 비어 있으면 학습으로 안 이어진다.
  final List<TermOx> quiz;

  /// 학습 카드를 띄울 수 있는 용어인지. 설명과 문제가 다 있어야 한다.
  bool get hasLesson => summary.isNotEmpty && quiz.length >= 2;
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
    quiz: [
      TermOx(
        statement: '기준금리는 은행마다 다르게 정한다.',
        answer: false,
        why: '한국은행 금융통화위원회가 나라에 하나로 정한다. 은행마다 다른 건 그 위에 붙는 예금·대출 금리다.',
      ),
      TermOx(
        statement: '기준금리가 오르면 대출 이자 부담도 커진다.',
        answer: true,
        why: '은행이 돈을 구해 오는 값이 비싸지니 대출 금리에 그대로 얹힌다.',
      ),
    ],
  ),
  FinanceTerm(term: '예금금리', categoryId: 'saving'),
  FinanceTerm(term: '정기예금', categoryId: 'saving'),
  FinanceTerm(
    term: '적금',
    categoryId: 'saving',
    summary: '매달 정해진 돈을 나눠 넣어 만기에 목돈으로 받는 저축.',
    forMe: '용돈에서 매달 조금씩 떼어 두는 습관을 만들기에 좋다.',
    quiz: [
      TermOx(
        statement: '연 5% 적금에 매달 10만 원씩 넣으면, 넣은 돈 전부에 5%를 받는다.',
        answer: false,
        why: '첫 달 넣은 돈만 12개월치 이자를 받고 마지막 달 돈은 한 달치만 받는다. 실제로 손에 쥐는 이자는 절반쯤이다.',
      ),
      TermOx(
        statement: '만기 전에 해지하면 약속한 금리를 다 못 받는다.',
        answer: true,
        why: '중도해지 금리가 따로 있는데 보통 훨씬 낮다. 만기를 채우는 게 이자의 대부분이다.',
      ),
    ],
  ),
  FinanceTerm(
    term: '예금',
    categoryId: 'saving',
    summary: '은행에 돈을 맡기고 이자를 받는 것. 목돈을 한 번에 넣어 두는 쪽이다.',
    forMe: '당장 안 쓸 목돈은 그냥 통장에 두는 것보다 이자가 붙는다.',
    quiz: [
      TermOx(
        statement: '예금은 맡긴 원금이 줄어들 수 있다.',
        answer: false,
        why: '예금은 원금이 보장된다. 원금이 줄 수 있는 건 주식·펀드처럼 투자하는 상품이다.',
      ),
      TermOx(
        statement: '정기예금은 만기까지 두는 조건으로 더 높은 금리를 준다.',
        answer: true,
        why: '은행이 그 돈을 얼마 동안 쓸 수 있는지가 정해지기 때문이다. 그래서 중간에 깨면 금리가 깎인다.',
      ),
    ],
  ),
  FinanceTerm(term: '수신', categoryId: 'saving'),
  FinanceTerm(
    term: '금리',
    categoryId: 'saving',
    summary: '돈을 빌려 쓴 값. 원금에 몇 %를 더 주고받는지를 말한다.',
    forMe: '예금 금리는 내가 받는 돈, 대출 금리는 내가 내는 돈이다.',
    quiz: [
      TermOx(
        statement: '금리는 돈을 빌린 사람만 신경 쓰면 되는 숫자다.',
        answer: false,
        why: '예금·적금은 내가 은행에 돈을 빌려주는 쪽이다. 금리가 높을수록 내가 받는 이자가 는다.',
      ),
      TermOx(
        statement: '같은 돈을 빌려도 금리가 낮을수록 총 이자가 적다.',
        answer: true,
        why: '이자는 원금 × 금리 × 기간이다. 1%p 차이도 몇 년 쌓이면 큰 돈이 된다.',
      ),
    ],
  ),
  FinanceTerm(term: '이자', categoryId: 'saving'),

  // 신용
  FinanceTerm(
    term: '주택담보대출',
    categoryId: 'credit',
    summary: '집을 담보로 잡히고 받는 대출. 줄여서 주담대라고 부른다.',
    forMe: '담보가 있어 금리가 낮은 대신, 못 갚으면 그 집이 넘어간다.',
    quiz: [
      TermOx(
        statement: '주택담보대출은 보통 신용대출보다 금리가 낮다.',
        answer: true,
        why: '못 갚아도 은행이 집을 팔아 회수할 수 있어 떼일 위험이 작기 때문이다.',
      ),
      TermOx(
        statement: '집값 전액을 다 빌릴 수 있다.',
        answer: false,
        why: 'LTV(담보인정비율) 규제가 있어 집값의 정해진 비율까지만 빌려준다.',
      ),
    ],
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
    quiz: [
      TermOx(
        statement: '카드값이나 통신비를 연체하면 신용점수가 떨어진다.',
        answer: true,
        why: '약속한 날짜에 갚았는지가 가장 크게 반영된다. 짧은 연체도 기록에 남는다.',
      ),
      TermOx(
        statement: '카드를 아예 안 쓰면 신용점수가 가장 높다.',
        answer: false,
        why: '갚은 기록이 있어야 점수가 쌓인다. 기록이 아예 없으면 판단할 자료가 없어 점수가 잘 안 오른다.',
      ),
    ],
  ),
  FinanceTerm(
    term: '대출',
    categoryId: 'credit',
    summary: '은행에서 돈을 빌리고 원금과 이자를 나눠 갚는 것.',
    forMe: '갚는 돈은 원금 + 이자다. 빌린 액수보다 항상 많이 나간다.',
    quiz: [
      TermOx(
        statement: '원금을 빨리 갚을수록 내가 내는 총 이자가 줄어든다.',
        answer: true,
        why: '이자는 남아 있는 원금에만 붙는다. 원금이 줄면 그 다음 달 이자도 같이 준다.',
      ),
      TermOx(
        statement: '대출을 늦게 갚아도 신용점수와는 상관없다.',
        answer: false,
        why: '연체는 신용점수에 바로 반영된다. 점수가 떨어지면 다음 대출 금리가 올라간다.',
      ),
    ],
  ),
  FinanceTerm(term: '연체', categoryId: 'credit'),
  FinanceTerm(term: '차주', categoryId: 'credit'),

  // 주식&투자
  FinanceTerm(
    term: '코스피',
    categoryId: 'stock',
    summary: '유가증권시장에 상장된 회사들의 주가를 묶어 만든 한국 대표 주가지수.',
    forMe: '코스피가 올랐다는 건 한국 대표 기업들 주가가 대체로 올랐다는 뜻이다.',
    quiz: [
      TermOx(
        statement: '코스피는 특정 회사 한 곳의 주가를 말한다.',
        answer: false,
        why: '시장에 상장된 회사 전체를 묶어 만든 지수다. 회사 하나가 아니라 시장 전체의 온도계다.',
      ),
      TermOx(
        statement: '코스피가 올라도 내가 가진 종목은 내렸을 수 있다.',
        answer: true,
        why: '지수는 평균이다. 덩치 큰 몇 종목이 끌어올리면 나머지가 내려도 지수는 오른다.',
      ),
    ],
  ),
  FinanceTerm(term: '코스닥', categoryId: 'stock'),
  FinanceTerm(term: '공모주', categoryId: 'stock'),
  FinanceTerm(
    term: '증시',
    categoryId: 'stock',
    summary: '주식이 사고팔리는 시장을 통틀어 부르는 말.',
    forMe: '뉴스의 "증시가 좋다"는 주식 시장 분위기 전반을 말한다.',
    quiz: [
      TermOx(
        statement: '증시는 코스피와 코스닥을 함께 아우르는 말이다.',
        answer: true,
        why: '두 시장을 굳이 나눠 부르지 않을 때 쓰는 통칭이다.',
      ),
      TermOx(
        statement: '한국 증시는 24시간 아무 때나 거래할 수 있다.',
        answer: false,
        why: '정규 거래는 평일 오전 9시부터 오후 3시 30분까지다. 그 앞뒤로 시간외 거래가 조금 있을 뿐이다.',
      ),
    ],
  ),
  FinanceTerm(term: '주가', categoryId: 'stock'),
  FinanceTerm(term: '배당', categoryId: 'stock'),
  FinanceTerm(term: '펀드', categoryId: 'stock'),
  FinanceTerm(
    term: 'ETF',
    categoryId: 'stock',
    summary: '여러 종목을 한 바구니에 담아, 주식처럼 사고파는 상품.',
    forMe: '한 주만 사도 수십~수백 개 회사에 나눠 투자한 셈이 된다.',
    quiz: [
      TermOx(
        statement: 'ETF는 주식시장이 열려 있는 동안 실시간으로 사고팔 수 있다.',
        answer: true,
        why: '이게 일반 펀드와 다른 점이다. 펀드는 하루 한 번 정해진 값으로 정산된다.',
      ),
      TermOx(
        statement: 'ETF는 여러 종목에 나눠 담으니 원금이 보장된다.',
        answer: false,
        why: '나눠 담으면 한 회사가 망했을 때의 충격이 줄 뿐이다. 시장 전체가 내리면 ETF도 같이 내린다.',
      ),
    ],
  ),
  FinanceTerm(
    term: '국채',
    categoryId: 'stock',
    summary: '나라가 돈을 빌리면서 발행하는 빚 문서. 사 두면 정해진 이자를 받는다.',
    forMe: '국채 금리는 예금·대출 금리가 따라 움직이는 기준선 노릇을 한다.',
    quiz: [
      TermOx(
        statement: '국채는 나라가 갚는 빚이라 회사채보다 안전하다고 본다.',
        answer: true,
        why: '회사는 망할 수 있지만 나라는 세금을 걷을 수 있다. 그래서 금리도 회사채보다 낮다.',
      ),
      TermOx(
        statement: '국채 금리가 오르면 이미 갖고 있던 국채 가격도 같이 오른다.',
        answer: false,
        why: '금리와 채권 가격은 반대로 움직인다. 새로 나온 채권이 이자를 더 주면, 이자가 적은 옛 채권은 값을 깎아야 팔린다.',
      ),
    ],
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
    quiz: [
      TermOx(
        statement: '연말정산으로 세금을 더 내야 하는 경우도 있다.',
        answer: true,
        why: '미리 뗀 돈이 실제 세금보다 적었으면 그만큼 더 낸다. 항상 돌려받는 절차가 아니다.',
      ),
      TermOx(
        statement: '연말정산은 회사를 다니지 않아도 누구나 하는 것이다.',
        answer: false,
        why: '연말정산은 근로소득자 몫이다. 프리랜서·사업자는 이듬해 5월 종합소득세로 따로 신고한다.',
      ),
    ],
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
    quiz: [
      TermOx(
        statement: '알바로 번 돈에도 세금이 붙는다.',
        answer: true,
        why: '소득이면 종류를 가리지 않고 붙는다. 다만 버는 돈이 적으면 신고해서 대부분 돌려받는다.',
      ),
      TermOx(
        statement: '물건을 살 때 내는 부가가치세는 세금이 아니다.',
        answer: false,
        why: '값에 이미 10%가 포함돼 있다. 가게가 대신 받아 나라에 낼 뿐, 내는 사람은 나다.',
      ),
    ],
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
    quiz: [
      TermOx(
        statement: '보장성 보험은 사고가 안 나면 낸 보험료를 대부분 못 돌려받는다.',
        answer: true,
        why: '그 돈이 사고를 당한 사람에게 갔기 때문이다. 만기에 돌려주는 저축성 보험은 그만큼 보험료가 비싸다.',
      ),
      TermOx(
        statement: '보험료가 쌀수록 무조건 좋은 보험이다.',
        answer: false,
        why: '보험료가 싸면 보장 범위나 한도도 같이 줄어든다. 필요한 게 보장되는지를 먼저 봐야 한다.',
      ),
    ],
  ),

  // 용돈&지출 — 물가·환율은 거시 지표지만 생활비에 바로 닿아서 이쪽에 둔다.
  FinanceTerm(
    term: '소비자물가',
    categoryId: 'allowance',
    summary: '사람들이 자주 사는 물건·서비스 값을 모아 만든 대표 물가 지표.',
    forMe: '뉴스의 "물가 3% 상승"은 거의 이 지표를 말한다.',
    quiz: [
      TermOx(
        statement: '소비자물가는 생활에 쓰는 품목들의 값을 모아 계산한다.',
        answer: true,
        why: '식료품·교통·통신처럼 실제로 자주 사는 품목을 골라 묶는다.',
      ),
      TermOx(
        statement: '아파트 매매가격도 소비자물가에 그대로 들어간다.',
        answer: false,
        why: '집을 사는 건 소비가 아니라 자산 거래라 빠진다. 대신 월세 같은 주거비가 들어간다.',
      ),
    ],
  ),
  FinanceTerm(
    term: '인플레이션',
    categoryId: 'allowance',
    summary: '물가가 전반적으로 계속 오르는 현상.',
    forMe: '가만히 둔 현금은 인플레이션만큼 매년 힘이 빠진다.',
    quiz: [
      TermOx(
        statement: '인플레이션이 심하면 현금을 그냥 들고 있는 게 손해일 수 있다.',
        answer: true,
        why: '돈의 액수는 그대로인데 살 수 있는 양이 줄기 때문이다.',
      ),
      TermOx(
        statement: '인플레이션을 잡으려고 중앙은행은 보통 금리를 내린다.',
        answer: false,
        why: '반대다. 금리를 올려 빌리고 쓰는 걸 줄이게 만들어 물가를 누른다.',
      ),
    ],
  ),
  FinanceTerm(term: '생활비', categoryId: 'allowance'),
  FinanceTerm(
    term: '물가',
    categoryId: 'allowance',
    summary: '물건과 서비스 값을 전체적으로 묶어 본 수준.',
    forMe: '물가가 오르면 같은 용돈으로 살 수 있는 게 줄어든다.',
    quiz: [
      TermOx(
        statement: '물가가 오르면 같은 돈으로 살 수 있는 게 줄어든다.',
        answer: true,
        why: '돈의 가치가 떨어진 것과 같은 말이다.',
      ),
      TermOx(
        statement: '물가 상승률이 3%에서 1%로 낮아지면 물건값이 내려간 것이다.',
        answer: false,
        why: '오르는 속도가 느려진 것뿐이고 값은 여전히 오르는 중이다. 실제로 내리려면 상승률이 마이너스여야 한다.',
      ),
    ],
  ),
  FinanceTerm(
    term: '환율',
    categoryId: 'allowance',
    summary: '우리 돈과 외국 돈을 바꾸는 비율. 보통 1달러가 몇 원인지로 본다.',
    forMe: '환율이 오르면 해외 직구와 여행 비용이 그만큼 비싸진다.',
    quiz: [
      TermOx(
        statement: '원/달러 환율이 1,300원에서 1,400원이 되면 원화 가치가 떨어진 것이다.',
        answer: true,
        why: '같은 1달러를 사는 데 원화를 더 줘야 하기 때문이다.',
      ),
      TermOx(
        statement: '환율이 오르면 수입 물건값이 싸진다.',
        answer: false,
        why: '수입할 때 원화를 더 줘야 해서 값이 오른다. 기름·밀가루처럼 수입에 기대는 품목이 먼저 오른다.',
      ),
    ],
  ),
  FinanceTerm(term: '용돈', categoryId: 'allowance'),
  FinanceTerm(
    term: '연금',
    categoryId: 'allowance',
    summary: '일할 때 모아 두었다가 나이 들어 매달 나눠 받는 돈.',
    forMe: '국민연금 말고 퇴직연금·개인연금이 더 있고, 개인연금은 세액공제를 받는다.',
    quiz: [
      TermOx(
        statement: '국민연금은 직장에 다니면 월급에서 자동으로 빠져나간다.',
        answer: true,
        why: '회사가 절반을 같이 내고, 내 몫은 월급에서 미리 뗀다.',
      ),
      TermOx(
        statement: '연금은 무조건 한 번에 목돈으로 받는다.',
        answer: false,
        why: '이름 그대로 나눠 받는 게 기본이다. 조건에 따라 일시금으로 받는 경우가 있을 뿐이다.',
      ),
    ],
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
