/// 관심 카테고리 마스터 데이터.
///
/// [id]는 QuizCategory enum의 name과 동일하게 맞춰두었다.
/// (allowance / saving / stock / insurance / tax / credit)
/// 회원가입 직후 카테고리 선택 화면과 홈 화면의 카테고리 스위처가 이 목록을 함께 사용한다.
class InterestCategory {
  const InterestCategory({
    required this.id,
    required this.emoji,
    required this.name,
    required this.description,
  });

  final String id;
  final String emoji;
  final String name;
  final String description;
}

const List<InterestCategory> kInterestCategories = [
  InterestCategory(
    id: 'allowance',
    emoji: '💸',
    name: '용돈&지출관리',
    description: '똑똑한 소비 습관',
  ),
  InterestCategory(
    id: 'saving',
    emoji: '🏦',
    name: '저축&예금',
    description: '차곡차곡 모으기',
  ),
  InterestCategory(
    id: 'stock',
    emoji: '📈',
    name: '주식&투자',
    description: '투자 기초 다지기',
  ),
  InterestCategory(
    id: 'insurance',
    emoji: '🛡️',
    name: '보험',
    description: '위험에 대비하기',
  ),
  InterestCategory(
    id: 'tax',
    emoji: '🧾',
    name: '세금',
    description: '아는 만큼 아끼기',
  ),
  InterestCategory(
    id: 'credit',
    emoji: '💳',
    name: '신용&대출',
    description: '신용점수 관리하기',
  ),
];

/// 유효한 관심 카테고리 id 집합.
const Set<String> kInterestCategoryIds = {
  'allowance',
  'saving',
  'stock',
  'insurance',
  'tax',
  'credit',
};

/// 저장된 id 목록에서 현재 학습 카테고리 1개를 고른다.
String? resolveActiveInterestCategoryId(List<String> ids) {
  for (final id in ids) {
    if (kInterestCategoryIds.contains(id)) return id;
  }
  return null;
}

InterestCategory? interestCategoryById(String id) {
  for (final category in kInterestCategories) {
    if (category.id == id) return category;
  }
  return null;
}
