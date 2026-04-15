import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/foundation.dart';

class RazorpayService {
  late Razorpay _razorpay;
  Function(PaymentSuccessResponse)? onSuccess;
  Function(PaymentFailureResponse)? onFailure;
  Function(ExternalWalletResponse)? onExternalWallet;

  RazorpayService() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (onSuccess != null) onSuccess!(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (onFailure != null) onFailure!(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (onExternalWallet != null) onExternalWallet!(response);
  }

  void openCheckout({
    required double amount, 
    required String name, 
    required String description, 
    required String contact, 
    required String email
  }) {
    var options = {
      'key': 'rzp_test_YourTestKeyHere', // Replace with real key
      'amount': (amount * 100).toInt(), // Razorpay expects amount in paise
      'name': name,
      'description': description,
      'prefill': {
        'contact': contact,
        'email': email
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: e');
    }
  }

  void dispose() {
    _razorpay.clear(); // Removes all listeners
  }
}
