/// 한 화면에 질문 하나씩 받는 가입 흐름이 단계 사이에서 들고 다니는 입력값.
///
/// 프로필 문서(`users/{uid}`)는 마지막 약관 화면에서 한 번에 만든다.
/// Auth 계정은 비밀번호 화면에서 만들어진다 — 인증 메일을 보내려면
/// 계정이 먼저 있어야 하기 때문이다.
class SignupDraft {
  String nickname = '';
  String email = '';
  bool marketingConsent = false;
}
