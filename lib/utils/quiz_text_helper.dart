import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/quiz_session.dart';

/// xlsx 원본 메타 꼬리표 제거 — UI에는 본문만 표시.
/// 앞에 붙은 `[난이도 1·객관식·…]`과 뒤에 붙은 `(난이도 7 사례 63)` 두 모양이 있다.
String stripQuizMetadataPrefix(String raw) {
  var text = raw.trim().replaceFirst(_metadataSuffix, '');
  if (!text.startsWith('[')) return text;
  final close = text.indexOf(']');
  if (close <= 0) return text;
  return text.substring(close + 1).trim();
}

final _metadataSuffix = RegExp(r'\s*\(난이도 \d+ 사례 \d+\)$');

bool isFirestorePermissionDenied(Object error) {
  if (error is FirebaseException) {
    return error.code == 'permission-denied';
  }
  try {
    final dynamic boxed = error;
    final inner = boxed.error;
    if (inner != null && inner != error) {
      return isFirestorePermissionDenied(inner as Object);
    }
  } catch (_) {}
  final message = error.toString().toLowerCase();
  return message.contains('permission-denied') ||
      message.contains('missing or insufficient permissions');
}

String firestorePermissionDeniedMessage() =>
    'Firestore 권한이 없어요. 개발용 firestore.rules가 배포돼 있는지 확인해 주세요. '
    '(node scripts/deploy_firestore_rules.mjs)';

/// Firestore 트랜잭션·웹 interop 오류를 [QuizSessionException]으로 변환.
QuizSessionException mapQuizSubmitError(
  Object error, {
  String fallback = '답안 제출에 실패했어요.',
}) {
  if (error is QuizSessionException) return error;

  if (error is FirebaseException) {
    if (error.code == 'permission-denied') {
      return QuizSessionException(firestorePermissionDeniedMessage());
    }
    final msg = error.message?.trim();
    if (msg != null && msg.isNotEmpty) {
      return QuizSessionException(msg);
    }
  }

  try {
    final dynamic boxed = error;
    final inner = boxed.error;
    if (inner != null && inner != error) {
      return mapQuizSubmitError(inner as Object, fallback: fallback);
    }
  } catch (_) {}

  if (isFirestorePermissionDenied(error)) {
    return QuizSessionException(firestorePermissionDeniedMessage());
  }

  return QuizSessionException(fallback);
}
