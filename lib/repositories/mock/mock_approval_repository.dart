import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

import '../../services/local_storage.dart';
import '../approval_repository.dart';
import 'counter_utils.dart';

class MockApprovalRepository implements ApprovalRepository {
  MockApprovalRepository({
    Future<Box<Map<String, dynamic>>>? approvalBox,
  }) : _approvalBoxFuture =
            approvalBox ?? LocalStorage.openBox<Map<String, dynamic>>('approvalTokens');

  final Future<Box<Map<String, dynamic>>> _approvalBoxFuture;

  static const _counterKey = '__approval_id_counter__';

  Future<Box<Map<String, dynamic>>> get _box => _approvalBoxFuture;

  @override
  Future<ApprovalToken> create(ApprovalToken token) async {
    final box = await _box;
    final normalized = await _ensureDefaults(token, box);
    await box.put(normalized.id, normalized.toMap());
    return normalized;
  }

  @override
  Future<ApprovalToken?> fetch(String tokenId) async {
    final box = await _box;
    final value = box.get(tokenId);
    if (value is Map) {
      return ApprovalToken.fromMap(Map<String, dynamic>.from(value));
    }
    return null;
  }

  @override
  Stream<ApprovalToken?> watch(String tokenId) async* {
    yield await fetch(tokenId);
    final box = await _box;
    yield* box.watch(key: tokenId).asyncMap((event) => fetch(tokenId));
  }

  @override
  Future<void> update(ApprovalToken token) async {
    final box = await _box;
    final existing = await fetch(token.id);
    if (existing != null && existing.status != ApprovalStatus.pending) {
      if (token.status != existing.status) {
        throw StateError(
          'Approval token ${token.id} has already been decided with status: ${existing.status}',
        );
      }
    }
    final transitioningToDecision =
        (existing?.status ?? ApprovalStatus.pending) == ApprovalStatus.pending &&
            token.status != ApprovalStatus.pending;
    final decidedAt = token.status == ApprovalStatus.pending
        ? token.decidedAt
        : (token.decidedAt ??
            (transitioningToDecision ? DateTime.now() : existing?.decidedAt));
    final normalized = ApprovalToken(
      id: token.id,
      garageId: token.garageId,
      quotationId: token.quotationId,
      status: token.status,
      customerComment: token.customerComment ?? existing?.customerComment,
      createdAt: existing?.createdAt ?? token.createdAt,
      decidedAt: decidedAt,
      expiresAt: token.expiresAt ?? existing?.expiresAt,
      used: token.used,
      usedAt: token.usedAt ?? existing?.usedAt,
    );
    await box.put(normalized.id, normalized.toMap());
  }

  @override
  Future<void> delete(String tokenId) async {
    final box = await _box;
    await box.delete(tokenId);
  }

  Future<ApprovalToken> _ensureDefaults(
    ApprovalToken token,
    Box<Map<String, dynamic>> box,
  ) async {
    final id = token.id.isNotEmpty ? token.id : await _nextId(box);
    return ApprovalToken(
      id: id,
      garageId: token.garageId,
      quotationId: token.quotationId,
      status: token.status,
      customerComment: token.customerComment,
      createdAt: token.createdAt ?? DateTime.now(),
      decidedAt: token.decidedAt,
      expiresAt: token.expiresAt,
      used: token.used,
      usedAt: token.usedAt,
    );
  }

  Future<String> _nextId(Box<Map<String, dynamic>> box) async {
    final next = await nextCounterValue(box, _counterKey);
    return 'approval-$next';
  }
}
