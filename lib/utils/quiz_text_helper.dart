import 'package:cloud_firestore/cloud_firestore.dart';

/// xlsx 원본 `[난이도 1·객관식·…]` 메타 접두사 제거 — UI에는 본문만 표시.
String stripQuizMetadataPrefix(String raw) {
  final trimmed = raw.trim();
  if (!trimmed.startsWith('[')) return trimmed;
  final close = trimmed.indexOf(']');
  if (close <= 0) return trimmed;
  return trimmed.substring(close + 1).trim();
}

bool isFirestorePermissionDenied(Object error) {
  if (error is FirebaseException) {
    return error.code == 'permission-denied';
  }
  final message = error.toString().toLowerCase();
  return message.contains('permission-denied') ||
      message.contains('missing or insufficient permissions');
}

String firestorePermissionDeniedMessage() =>
    'Firestore 권한이 없어요. Firebase Console에 개발용 firestore.rules를 게시했는지 확인해 주세요.';
