const String approvalBaseUrl = String.fromEnvironment(
  'APPROVAL_BASE_URL',
  defaultValue: 'https://garage-mvp.local/approve',
);

String buildApprovalLink(String tokenId) => '$approvalBaseUrl/$tokenId';
