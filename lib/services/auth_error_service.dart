/// Service for handling and formatting authentication errors
class AuthErrorService {
  /// Maps Firebase authentication error codes to user-friendly messages
  static String getErrorMessage(String errorCode, {String? errorMessage}) {
    switch (errorCode.toLowerCase()) {
      // Email/User Related Errors
      case 'email-already-in-use':
        return 'This email address is already registered. Please use a different email or try logging in.';
      case 'user-not-found':
        return 'No account found with this email. Please check your email or create a new account.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support for assistance.';

      // Password Related Errors
      case 'wrong-password':
        return 'Incorrect password. Please check your password and try again.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 8 characters with uppercase, lowercase, and numbers.';
      case 'invalid-password':
        return 'Password is invalid. Please enter a valid password.';

      // Credential/Authentication Errors
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials and try again.';
      case 'invalid-email':
        return 'The email address is not properly formatted. Please enter a valid email.';
      case 'invalid-auth-code':
        return 'Invalid authentication code. Please try again.';

      // Network Related Errors
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      case 'too-many-requests':
        return 'Too many login attempts. Please wait a few minutes before trying again.';
      case 'operation-not-allowed':
        return 'This operation is not allowed. Please contact support.';

      // Account Related Errors
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email. Please use a different sign-in method.';
      case 'provider-already-linked':
        return 'This account is already linked to another provider.';
      case 'credential-already-in-use':
        return 'This credential is already in use by another account.';

      // Session/Token Errors
      case 'expired-action-code':
        return 'The verification link has expired. Please request a new one.';
      case 'invalid-action-code':
        return 'The verification code is invalid or has expired. Please request a new one.';
      case 'user-mismatch':
        return 'The user does not match. Please sign in with the correct account.';
      case 'invalid-verification-code':
        return 'The verification code is invalid. Please check and try again.';
      case 'invalid-session-cookie':
        return 'Session has expired. Please sign in again.';

      // Generic/Unknown Errors
      case 'internal-error':
        return 'An internal server error occurred. Please try again later.';
      case 'unknown':
      default:
        return errorMessage?.isNotEmpty == true
            ? 'Authentication failed: $errorMessage'
            : 'An unexpected error occurred. Please try again.';
    }
  }

  /// Gets an appropriate error title based on error code
  static String getErrorTitle(String errorCode) {
    switch (errorCode.toLowerCase()) {
      case 'email-already-in-use':
      case 'account-exists-with-different-credential':
        return 'Email Already Registered';
      case 'user-not-found':
      case 'account-not-found':
        return 'Account Not Found';
      case 'wrong-password':
      case 'invalid-password':
      case 'invalid-credential':
        return 'Invalid Credentials';
      case 'weak-password':
        return 'Weak Password';
      case 'invalid-email':
        return 'Invalid Email';
      case 'network-request-failed':
        return 'Network Error';
      case 'too-many-requests':
        return 'Too Many Attempts';
      case 'user-disabled':
        return 'Account Disabled';
      case 'expired-action-code':
      case 'invalid-action-code':
        return 'Verification Expired';
      default:
        return 'Authentication Error';
    }
  }

  /// Gets an appropriate icon for the error
  static String getErrorIcon(String errorCode) {
    switch (errorCode.toLowerCase()) {
      case 'network-request-failed':
        return 'wifi_off';
      case 'too-many-requests':
        return 'schedule';
      case 'user-disabled':
        return 'person_off';
      case 'email-already-in-use':
      case 'account-exists-with-different-credential':
        return 'email';
      case 'weak-password':
        return 'lock';
      default:
        return 'error_outline';
    }
  }

  /// Determines if an error is recoverable
  static bool isRecoverable(String errorCode) {
    final nonRecoverableErrors = [
      'user-disabled',
      'operation-not-allowed',
      'internal-error',
    ];
    return !nonRecoverableErrors.contains(errorCode.toLowerCase());
  }

  /// Checks if error is a network-related error
  static bool isNetworkError(String errorCode) {
    return errorCode.toLowerCase().contains('network') ||
        errorCode.toLowerCase().contains('request-failed');
  }

  /// Checks if error is a rate-limiting error
  static bool isRateLimited(String errorCode) {
    return errorCode.toLowerCase().contains('too-many-requests');
  }
}
