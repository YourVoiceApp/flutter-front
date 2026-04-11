/// Which part of the Google → backend sign-in flow failed (for in-app diagnostics).
enum GoogleAuthFailureStage {
  /// Google SDK, account picker, or idToken.
  google,

  /// HTTP call to Spring `/auth/google` (connection or error response).
  backend,

  /// SharedPreferences / local profile after a successful API response.
  local,
}

/// Thrown with a short [title] and [detail] suitable for SnackBar / dialog.
class GoogleAuthFlowException implements Exception {
  const GoogleAuthFlowException({
    required this.stage,
    required this.title,
    required this.detail,
    this.cause,
  });

  final GoogleAuthFailureStage stage;
  final String title;
  final String detail;
  final Object? cause;

  @override
  String toString() => 'GoogleAuthFlowException($stage): $title — $detail';
}
