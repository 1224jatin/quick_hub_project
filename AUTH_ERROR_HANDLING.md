# Authentication Error Handling Documentation

## Overview
This document describes the comprehensive authentication error handling system implemented in the QuickHub project. The system provides user-friendly error messages and recovery options for any authentication errors.

## Components

### 1. **AuthErrorService** (`lib/services/auth_error_service.dart`)
A utility service that maps Firebase authentication error codes to user-friendly messages with proper error titles and recovery suggestions.

**Key Features:**
- `getErrorMessage(errorCode, errorMessage)` - Returns user-friendly error message
- `getErrorTitle(errorCode)` - Returns appropriate error title
- `isRecoverable(errorCode)` - Determines if error is recoverable
- `isNetworkError(errorCode)` - Identifies network-related errors
- `isRateLimited(errorCode)` - Identifies rate-limiting errors

**Supported Error Codes:**
```
Email/User Related:
- email-already-in-use
- user-not-found
- user-disabled

Password Related:
- wrong-password
- weak-password
- invalid-password

Credential/Authentication:
- invalid-credential
- invalid-email
- invalid-auth-code

Network Related:
- network-request-failed
- too-many-requests
- operation-not-allowed

Account Related:
- account-exists-with-different-credential
- provider-already-linked
- credential-already-in-use

Session/Token:
- expired-action-code
- invalid-action-code
- user-mismatch
- invalid-verification-code
- invalid-session-cookie

And more...
```

### 2. **ErrorScaffold Widgets** (`lib/view/widgets/auth_error_scaffold.dart`)

#### AuthErrorScaffold
A full-page error display widget with:
- Icon indicator matching error type
- Error title and detailed message
- Actionable buttons (Retry, Go Back)
- Customizable styling and actions

**Usage:**
```dart
AuthErrorScaffold(
  errorTitle: "Login Failed",
  errorMessage: "Invalid email or password.",
  onRetry: () => _handleLogin(),
  onBack: () => Navigator.pop(context),
)
```

#### AuthErrorDialog
A modal dialog for displaying auth errors with:
- Circular error icon
- Error title and message
- Action buttons (Cancel, Retry)
- Scrollable content for long messages

**Usage:**
```dart
showDialog(
  context: context,
  builder: (context) => AuthErrorDialog(
    title: "Email Already Registered",
    message: "This email is already in use.",
    buttonText: "Try Different Email",
    onConfirm: () => _emailController.clear(),
    icon: Icons.email,
  ),
)
```

### 3. **Enhanced AuthViewModel** (`lib/view_models/auth_view_model.dart`)

New properties and methods:
```dart
String? get errorCode              // Stores Firebase error code
bool isRecoverableError(String)    // Check if error is recoverable
bool isNetworkError(String)        // Check if network error
bool isRateLimitError(String)      // Check if rate limit error
String getErrorTitle(String)       // Get error title
```

All authentication methods now:
- Capture error codes (`errorCode` property)
- Return both user message and error code
- Support better error categorization

### 4. **Login Screen Error Handling** (`lib/view/screens/login_screen.dart`)

**Features:**
- Detailed error dialog showing:
  - Error title and message
  - Context-specific recovery suggestions
  - Links to related actions (password reset, registration)
  - Network/rate limit indicators

**Error-Specific Handling:**
```dart
// User not found → Suggest registration
// Wrong password → Suggest password reset
// Network error → Check connection hint
// Too many attempts → Wait time suggestion
```

### 5. **Register Screen Error Handling** (`lib/view/screens/register_screen.dart`)

**Features:**
- OTP sending with comprehensive error handling
- Email validation with detailed feedback
- Password requirement indicators
- Registration error dialogs with recovery options

**Error Dialogs Include:**
- Invalid email suggestions
- Already registered email → Link to login
- Weak password → Requirements checklist
- Missing location info (for providers)
- Email verification reminders

## Error Handling Flow

### Login Flow
```
1. User enters credentials
2. Validation check (form)
3. Firebase authentication attempt
4. If error:
   - Map error code to message
   - Show detailed error dialog
   - Provide context-specific recovery options
   - Allow retry or navigate to other screens
5. If success:
   - Show success message
   - Navigate to home screen
```

### Registration Flow
```
1. User enters registration details
2. Email verification:
   - Send OTP
   - Validate email not already registered
   - Show errors with retry option
3. OTP verification:
   - Validate OTP
   - Show invalid code dialog
   - Allow retry or resend
4. Complete registration:
   - Firebase registration attempt
   - Show detailed error if fails
   - Display success if succeeds
```

### Password Reset Flow
```
1. User enters email
2. Firebase sends reset email
3. If error:
   - Show error code and message
   - Check for network issues
   - Provide retry option
4. If success:
   - Confirm email sending
   - Show completion message
```

## Implementation Guidelines

### Adding New Authentication Error Handling

1. **Add error code mapping in AuthErrorService:**
```dart
case 'your-error-code':
  return 'User-friendly message here';
```

2. **Ensure error code is captured:**
```dart
catch (e) {
  _setError(_mapFirebaseAuthError(e), errorCode: e.code);
}
```

3. **Use error code in UI for context-specific handling:**
```dart
if (authVM.errorCode == 'specific-error') {
  // Show specific widget or action
}
```

### Best Practices

1. **Always show both title and message**
   - Title: High-level error category
   - Message: Specific details and solution

2. **Provide actionable recovery**
   - Retry buttons for recoverable errors
   - Links to related screens
   - Clear next steps

3. **Handle network errors differently**
   - Show connection status
   - Suggest checking internet
   - Allow retry when connection restored

4. **Rate limiting handling**
   - Show time-based messages
   - Disable retry temporarily
   - Guide user to wait

5. **Maintain consistent error UI**
   - Use error icons for visual cues
   - Consistent color scheme (red for errors)
   - Consistent button labels

## Error Categories

### Critical Errors (Non-Recoverable)
- User account disabled
- Operation not allowed by system
- Internal server errors

**Handling:**
- Show full error scaffold
- No retry button
- Support contact suggestion

### Recoverable Errors
- Invalid credentials
- Network failures
- Weak password
- Too many attempts

**Handling:**
- Show error dialog or snackbar
- Include retry button
- Provide recovery suggestions

### Input Validation Errors
- Invalid email format
- Missing required fields
- Email already registered
- OTP mismatch

**Handling:**
- Show inline validation errors
- Field-specific error messages
- Clear recovery path

## Testing Error Handling

### Test Cases
1. Invalid email/password combination
2. Non-existent user login
3. Already registered email in signup
4. Weak password in signup
5. Network disconnection
6. Rate limiting (too many attempts)
7. Disabled account
8. Expired password reset link

### Mock Testing
```dart
// Test error mapping
final message = AuthErrorService.getErrorMessage('user-not-found');
expect(message, contains('No account found'));

// Test recoverability
expect(AuthErrorService.isRecoverable('invalid-credential'), true);
expect(AuthErrorService.isRecoverable('user-disabled'), false);
```

## User Experience Improvements

1. **Clear Error Messages**
   - Plain language, not technical jargon
   - Specific about what went wrong
   - Solution-focused

2. **Visual Hierarchy**
   - Error icons and colors
   - Bold error titles
   - Scrollable detailed messages

3. **Quick Recovery**
   - Prominent retry buttons
   - Contextual action links
   - Clear next steps

4. **Helpful Hints**
   - Password requirements
   - Internet connection checks
   - Recovery suggestions

## Debugging

Enable debug logging to track auth errors:
```dart
debugPrint("Auth error: ${e.code} - ${e.message}");
```

Check the `errorCode` and `errorMessage` properties in AuthViewModel for diagnosis.
