/// [ShopService.purchaseItem] 결과. 화면은 [status]/[message]만 보고 스낵바 문구를 정한다.
class ShopPurchaseResult {
  const ShopPurchaseResult({
    required this.status,
    this.seeds,
    this.energy,
    this.studyGuardCount,
    this.ownedShopItemIds,
    this.errorMessage,
  });

  final ShopPurchaseStatus status;

  /// 서버가 계산한 최신 값. 성공(`success`/`alreadyOwned`) 시에만 채워진다 —
  /// 화면은 이 값으로 로컬 프로필을 갱신해야 한다 (직접 뺄셈해서 덮어쓰지 않는다).
  final int? seeds;
  final int? energy;
  final int? studyGuardCount;
  final List<String>? ownedShopItemIds;

  /// [ShopPurchaseStatus.failed]일 때 서버/네트워크가 준 안내문.
  final String? errorMessage;

  bool get isSuccess =>
      status == ShopPurchaseStatus.success ||
      status == ShopPurchaseStatus.alreadyOwned;

  /// 사용자에게 보여줄 문구. 성공이면 null.
  String? get message {
    switch (status) {
      case ShopPurchaseStatus.success:
      case ShopPurchaseStatus.alreadyOwned:
        return null;
      case ShopPurchaseStatus.insufficientSeeds:
        return '씨앗이 부족해요.';
      case ShopPurchaseStatus.studyGuardMaxCapacity:
        return '방어권은 최대 4개까지 보유할 수 있어요.';
      case ShopPurchaseStatus.energyAlreadyFull:
        return '에너지가 이미 가득 차 있어요.';
      case ShopPurchaseStatus.notLoggedIn:
        return '로그인 정보가 없어요.';
      case ShopPurchaseStatus.failed:
        return errorMessage ?? '구매에 실패했어요.';
    }
  }
}

enum ShopPurchaseStatus {
  success,

  /// 이미 소유한 코스메틱 — 재구매 없이 성공 취급.
  alreadyOwned,
  insufficientSeeds,
  studyGuardMaxCapacity,
  energyAlreadyFull,
  notLoggedIn,

  /// 서버 호출 자체가 실패(네트워크·Functions 미배포 등). [ShopPurchaseResult.errorMessage] 참고.
  failed,
}
