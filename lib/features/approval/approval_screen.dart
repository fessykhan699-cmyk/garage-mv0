import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/controller_providers.dart';
import '../../models/quotation.dart';
import '../../repositories/approval_repository.dart';

final _tokenProvider =
    StreamProvider.autoDispose.family<ApprovalToken?, String>((ref, id) {
  return ref.watch(approvalControllerProvider).watchToken(id);
});

final _quotationProvider =
    FutureProvider.autoDispose.family<Quotation?, String>((ref, id) {
  return ref.watch(quotationControllerProvider).fetch(id);
});

class ApprovalScreen extends ConsumerStatefulWidget {
  const ApprovalScreen({super.key, required this.tokenId});

  final String tokenId;

  @override
  ConsumerState<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends ConsumerState<ApprovalScreen> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokenAsync = ref.watch(_tokenProvider(widget.tokenId));

    return Scaffold(
      appBar: AppBar(title: const Text('Approve Quotation')),
      body: tokenAsync.when(
        data: (token) {
          if (token == null) {
            return const Center(child: Text('Approval token not found.'));
          }
          final quotationAsync = ref.watch(_quotationProvider(token.quotationId));
          return quotationAsync.when(
            data: (quotation) => _buildContent(context, token, quotation),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ApprovalToken token,
    Quotation? quotation,
  ) {
    if (quotation == null) {
      return const Center(child: Text('Quotation not found.'));
    }
    final decided = token.status != ApprovalStatus.pending;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          quotation.quoteNumber,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text('Total: ${quotation.total.toStringAsFixed(2)}'),
        const SizedBox(height: 8),
        Text('Status: ${token.status.name}'),
        if ((token.customerComment ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Comment: ${token.customerComment}'),
        ],
        const SizedBox(height: 16),
        TextField(
          controller: _commentController,
          decoration: const InputDecoration(
            labelText: 'Comment (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          enabled: !decided,
        ),
        const SizedBox(height: 16),
        if (!decided)
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => _decide(context, token, approve: true),
                  child: const Text('Approve'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _decide(context, token, approve: false),
                  child: const Text('Reject'),
                ),
              ),
            ],
          ),
        if (decided)
          const Text('Decision recorded. Thank you for your response.'),
      ],
    );
  }

  Future<void> _decide(
    BuildContext context,
    ApprovalToken token, {
    required bool approve,
  }) async {
    try {
      if (approve) {
        await ref.read(approvalControllerProvider).approve(
              token.id,
              customerComment: _commentController.text.trim().isEmpty
                  ? null
                  : _commentController.text.trim(),
            );
      } else {
        await ref.read(approvalControllerProvider).reject(
              token.id,
              customerComment: _commentController.text.trim().isEmpty
                  ? null
                  : _commentController.text.trim(),
            );
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Decision saved')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit decision: $error')),
        );
      }
    }
  }
}
