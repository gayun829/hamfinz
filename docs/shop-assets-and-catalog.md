# 상점 이미지와 상품 추가

## 기본 상품

앱에 포함된 스킨 19개와 장식 7개는 `assets/figma/shop/skins/`,
`assets/figma/shop/accessories/`에서 읽는다. 기본 햄핀은 기본 제공이며 나머지는
579씨앗이다. 기본 제공은 DB의 소유 목록에 없어도 착용 가능하다.
로컬 상품 가격은 `ShopData.items`와 Functions의 `SHOP_CATALOG`를 같이 변경한다.

## 출시 후 상품

PNG를 Firebase Storage 등에 업로드하고 Firestore `shopItems/{고유상품ID}`에 등록한다.
기존 로컬 상품과 다른 ID를 사용한다. 로컬 상품 ID는 앱 정의가 우선이며,
예전 스프라이트 상품 ID(headband, cap, hoodie, glasses, bow, coconut)는 표시하지 않는다.

예시:

```json
{
  "name": "새로운 모자",
  "description": "햄핀을 꾸며보세요.",
  "price": 579,
  "category": "accessory",
  "imageUrl": "https://실제로-접근-가능한-이미지-주소",
  "sharedCanvas": true,
  "isActive": true
}
```

`category`는 `skin`, `accessory`, `pattern`, `background` 중 하나다.
스킨과 장식의 `sharedCanvas` 기본값은 true다. 동일한 384×384 프레임에서
몸 위치·크기를 유지하고 투명 PNG로 내보낸다(2배 출력도 가능).
장식은 몸을 숨겨서 내보낸다. 프레임 여백을 개별적으로 자르면 위치가 달라진다.
단독 배경 이미지 등 공통 좌표를 사용하지 않는 이미지는 false로 지정한다.
네트워크 상품은 앱을 재시작하거나 상점/옷장을 다시 열 때 로드된다.

장식은 현재 한 세트씩 착용한다. 화가 PNG는 모자와 앞치마가 하나의 세트다.
이미지 URL은 로그인한 앱에서 읽을 수 있어야 한다. 파일 자체를 Firestore에 넣지 않는다.

현재 개발 구매는 Firestore 클라이언트 트랜잭션을 사용한다. 출시용 Functions
구매로 전환할 때는 수정된 `functions/index.js`도 배포해야 한다.

## 정렬 SVG 적용

정렬 SVG 18개를 스킨 asset에 연결했다. 기존 스킨 6개의 ID와 가격은 유지하고 이미지만 SVG로 교체했다. 새 스킨 12개는 각각 579씨앗이다. 원시인(수염 없음)은 새 SVG가 없어 기존 PNG를 유지한다. 장식이 포함된 SVG는 완성형 스킨이며 기존 별도 장식 상품도 유지한다.
