import 'package:flutter/material.dart';

/// A reusable error scaffold widget for displaying authentication errors
class AuthErrorScaffold extends StatelessWidget {
  final String errorTitle;
  final String errorMessage;
  final VoidCallback onRetry;
  final VoidCallback? onBack;
  final String retryButtonText;
  final String backButtonText;
  final IconData errorIcon;
  final Color errorColor;

  const AuthErrorScaffold({
    super.key,
    this.errorTitle = "Authentication Error",
    required this.errorMessage,
    required this.onRetry,
    this.onBack,
    this.retryButtonText = "Try Again",
    this.backButtonText = "Go Back",
    this.errorIcon = Icons.error_outline,
    this.errorColor = Colors.redAccent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(errorTitle), centerTitle: true, elevation: 0),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Error Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: errorColor.withOpacity(0.1),
                  ),
                  child: Icon(errorIcon, size: 80, color: errorColor),
                ),
                const SizedBox(height: 24),

                // Error Title
                Text(
                  errorTitle,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Error Message
                Text(
                  errorMessage,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Action Buttons
                Column(
                  children: [
                    // Retry Button
                    ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: Text(retryButtonText),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: theme.primaryColor,
                      ),
                    ),
                    if (onBack != null) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: onBack,
                        icon: const Icon(Icons.arrow_back),
                        label: Text(backButtonText),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// An error dialog for displaying auth errors as a popup
class AuthErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onConfirm;
  final IconData icon;

  const AuthErrorDialog({
    super.key,
    this.title = "Error",
    required this.message,
    this.buttonText,
    this.onConfirm,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red.withOpacity(0.1),
        ),
        child: Icon(icon, color: Colors.red, size: 32),
      ),
      title: Text(title),
      content: SingleChildScrollView(child: Text(message)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm?.call();
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text(buttonText ?? "Retry"),
        ),
      ],
    );
  }
}
