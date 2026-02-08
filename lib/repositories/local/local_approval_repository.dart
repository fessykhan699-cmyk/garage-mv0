import 'dart:async';
import 'package:hive/hive.dart';

import '../../core/local_storage.dart';
import '../approval_repository.dart';

class LocalApprovalRepository implements ApprovalRepository {
  LocalApprovalRepository();

  final _streamController = StreamController<ApprovalToken?>.broadcast();

  // For local storage, we'll use a separate box for approval tokens
  Future<Box<Map<String, dynamic>>> get _box async {
    await LocalStorage.init();
    return await Hive.openBox<Map<String, dynamic>>('approvalTokens');
  }

  @override
  Future<ApprovalToken> create(ApprovalToken token) async {
    final box = await _box;
    final tokenData = token.toMap(useIsoFormat: true);
    await box.put(token.id, tokenData);
    _notifyListeners(token.id);
    return token;
  }

  @override
  Future<ApprovalToken?> fetch(String tokenId) async {
    final box = await _box;
    final data = box.get(tokenId);
    if (data == null) return null;
    return ApprovalToken.fromMap(Map<String, dynamic>.from(data));
  }

  @override
  Stream<ApprovalToken?> watch(String tokenId) async* {
    // Initial data
    yield await fetch(tokenId);
    
    // Listen to changes
    await for (final _ in _streamController.stream) {
      yield await fetch(tokenId);
    }
  }

  @override
  Future<void> update(ApprovalToken token) async {
    final box = await _box;
    final tokenData = token.toMap(useIsoFormat: true);
    await box.put(token.id, tokenData);
    _notifyListeners(token.id);
  }

  @override
  Future<void> delete(String tokenId) async {
    final box = await _box;
    await box.delete(tokenId);
    _notifyListeners(tokenId);
  }

  void _notifyListeners(String tokenId) {
    _streamController.add(null);
  }

  void dispose() {
    _streamController.close();
  }
}
