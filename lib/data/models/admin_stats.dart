class AdminStats {
  final int usersCount;
  final int signsCount;
  final int validatedSignsCount;
  final int pendingContributionsCount;
  final int approvedContributionsCount;
  final int rejectedContributionsCount;

  const AdminStats({
    required this.usersCount,
    required this.signsCount,
    required this.validatedSignsCount,
    required this.pendingContributionsCount,
    required this.approvedContributionsCount,
    required this.rejectedContributionsCount,
  });

  int get totalContributions =>
      pendingContributionsCount + approvedContributionsCount + rejectedContributionsCount;
}
