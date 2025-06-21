import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:driving_license_exam/services/api_service.dart';
import 'package:driving_license_exam/services/http_service.dart';
import 'package:driving_license_exam/services/subscription_service.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'models/subscription_models.dart';
import 'providers/subscription_notifier.dart';

class PaymentScreen extends StatefulWidget {
  final SubscriptionPlan selectedPlan;
  final int vehicleTypeId;
  final String vehicleTypeName;
  final VoidCallback? onSubscriptionCompleted;

  const PaymentScreen({
    super.key,
    required this.selectedPlan,
    required this.vehicleTypeId,
    required this.vehicleTypeName,
    this.onSubscriptionCompleted,
  });

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool isProcessingPayment = false;
  bool isCreatingLicense = false;
  String? paymentTransactionId;
  String? onePayTransactionId;

  // OnePay Configuration - Replace with your actual credentials
  static const String ONEPAY_APP_ID =
      "6JHC11908A89E00B3FD7D"; // Replace with your App ID
  static const String ONEPAY_APP_TOKEN =
      "542b1acf2150e870cd2ea7261a160fe47546fb20b05c3af03dfac7f32155c61618e767ebab9bd7f8.FN7I11908A89E00B3FDBE"; // Replace with your App Token
  static const String ONEPAY_HASH_SALT =
      "QCW911908A89E00B3FDA8"; // Replace with your Hash Salt
  static const String ONEPAY_API_BASE = "https://api.onepay.lk/v3";

  // Method to generate transaction reference
  String _generateTransactionReference() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999).toString().padLeft(6, '0');
    return "TXN$random";
  }

  // Method to generate hash for OnePay
  String _generateOnePayHash(
      String appId, String currency, double amount, String hashSalt) {
    final input = "$appId$currency$amount$hashSalt";
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Method to create OnePay payment request
  Future<Map<String, dynamic>> _createOnePayPaymentRequest() async {
    try {
      // Validate user ID
      final userId = await StorageService.getID();
      if (userId == null) {
        return {
          'success': false,
          'error': 'User not authenticated. Please log in.',
        };
      }

      // Fetch user details from a secure service (replace with your implementation)
      final userDetails = await _fetchUserDetails(userId);
      if (!userDetails['success']) {
        return {
          'success': false,
          'error': userDetails['error'] ?? 'Failed to fetch user details',
        };
      }

      // Generate transaction reference and validate amount
      final reference = _generateTransactionReference();
      final amount = widget.selectedPlan.price;
      if (amount <= 0) {
        return {
          'success': false,
          'error': 'Invalid payment amount',
        };
      }
      const currency =
          "LKR"; // Ensure this matches OnePay's supported currencies

      // Generate hash (ensure _generateOnePayHash matches OnePay's requirements)
      final hash = _generateOnePayHash(
        ONEPAY_APP_ID,
        currency,
        amount,
        ONEPAY_HASH_SALT,
      );

      // Build request body
      final requestBody = {
        "currency": currency,
        "app_id": ONEPAY_APP_ID,
        "hash": hash,
        "amount": amount.toStringAsFixed(2), // Ensure correct decimal places
        "reference": reference,
        "customer_first_name": userDetails['first_name'] ?? 'Unknown',
        "customer_last_name": userDetails['last_name'] ?? 'Unknown',
        "customer_phone_number": userDetails['phone_number'] ?? '',
        "customer_email": userDetails['email'] ?? '',
        "transaction_redirect_url":
            "https://your-app.com/payment-success", // Replace with dynamic or configured URL
        "additionalData":
            "subscription_${widget.selectedPlan.id}_vehicle_${widget.vehicleTypeId}",
      };

      // Log request (avoid logging sensitive data in production)
      debugPrint(
          "Creating OnePay payment request: ${requestBody['reference']}");

      // Send POST request
      final response = await HttpService.post(
        '$ONEPAY_API_BASE/checkout/link/',
        headers: {
          'Authorization': 'Bearer $ONEPAY_APP_TOKEN', // Ensure correct format
          'Content-Type': 'application/json',
        },
        body: requestBody, // Pass as Map<String, dynamic>
      );

      // Log response (avoid logging sensitive data)
      debugPrint("OnePay response status: ${response['status']}");

      // Validate response
      if (response['status'] == 200 && response['data'] != null) {
        final data = response['data'];
        if (data['gateway']?['redirect_url'] != null &&
            data['ipg_transaction_id'] != null) {
          return {
            'success': true,
            'payment_url': data['gateway']['redirect_url'],
            'transaction_id': data['ipg_transaction_id'],
            'reference': reference,
          };
        } else {
          return {
            'success': false,
            'error': 'Invalid response structure from OnePay',
          };
        }
      } else {
        return {
          'success': false,
          'error': response['message'] ??
              'Failed to create payment request (Status: ${response['status']})',
        };
      }
    } catch (e, stackTrace) {
      // Log error with stack trace for debugging
      debugPrint("Error creating OnePay payment request: $e\n$stackTrace");
      return {
        'success': false,
        'error': 'An error occurred while setting up payment: ${e.toString()}',
      };
    }
  }

// Placeholder method to fetch user details (implement based on your backend)
  Future<Map<String, dynamic>> _fetchUserDetails(String userId) async {
    try {
      final response = await HttpService.get(
        'http://88.222.215.134:3000/api/users/$userId', // Replace with your user endpoint
      );
      if (response['success'] == true) {
        final data = response['data'];
        return {
          'success': true,
          'first_name': data['first_name'],
          'last_name': data['last_name'],
          'phone_number': data['phone_number'],
          'email': data['email'],
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Failed to fetch user details',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Method to check payment status
  Future<Map<String, dynamic>> _checkPaymentStatus(String transactionId) async {
    try {
      final requestBody = {
        "app_id": ONEPAY_APP_ID,
        "onepay_transaction_id": transactionId,
      };

      final response = await HttpService.post(
        '$ONEPAY_API_BASE/transaction/status/',
        headers: {
          'Authorization': ONEPAY_APP_TOKEN,
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      if (response['status'] == 200) {
        final data = response['data'];
        return {
          'success': true,
          'paid': data['status'] == true,
          'amount': data['amount'],
          'paid_on': data['paid_on'],
        };
      } else {
        return {
          'success': false,
          'error': response['message'] ?? 'Failed to check payment status',
        };
      }
    } catch (e) {
      print("Error checking payment status: $e");
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Method to open OnePay payment in WebView
  Future<void> _openOnePayPayment(
      String paymentUrl, String transactionId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OnePayWebView(
          paymentUrl: paymentUrl,
          transactionId: transactionId,
          onPaymentResult: (success, txnId) async {
            if (success && txnId != null) {
              setState(() {
                onePayTransactionId = txnId;
              });

              // Verify payment status
              final statusResult = await _checkPaymentStatus(txnId);
              if (statusResult['success'] && statusResult['paid']) {
                await _handleSuccessfulPayment(txnId);
              } else {
                _showErrorDialog("Payment Verification Failed",
                    "Payment could not be verified. Please contact support.");
              }
            } else {
              _showErrorDialog(
                  "Payment Failed", "Payment was not completed successfully.");
            }
          },
        ),
      ),
    );
  }

  // Method to handle successful payment
  Future<void> _handleSuccessfulPayment(String transactionId) async {
    try {
      setState(() {
        isProcessingPayment = true;
        paymentTransactionId = transactionId;
      });

      // Create subscription after successful payment
      bool subscriptionCreated = await _createSubscription();

      if (subscriptionCreated) {
        // Create vehicle license after successful subscription
        bool licenseCreated = await _createVehicleLicense();
        await SubscriptionNotifier().fetchAndUpdateSubscription();

        if (licenseCreated) {
          _showSuccessDialog();
        } else {
          _showPartialSuccessDialog();
        }
      } else {
        _showErrorDialog("Subscription Failed",
            "Payment was successful but subscription activation failed. Please contact support.");
      }
    } catch (e) {
      _showErrorDialog("Error", "An error occurred: ${e.toString()}");
    } finally {
      setState(() {
        isProcessingPayment = false;
      });
    }
  }

  // Method to process payment with OnePay
  Future<void> _processPayment() async {
    try {
      setState(() {
        isProcessingPayment = true;
      });

      // Create OnePay payment request
      final paymentRequest = await _createOnePayPaymentRequest();

      if (paymentRequest['success']) {
        // Open OnePay payment in WebView
        await _openOnePayPayment(
          paymentRequest['payment_url'],
          paymentRequest['transaction_id'],
        );
      } else {
        _showErrorDialog("Payment Setup Failed",
            paymentRequest['error'] ?? "Failed to setup payment");
      }
      final subscriptionCreated = await _createSubscription();
      if (subscriptionCreated) {
        // Create vehicle license after successful subscription
        final licenseCreated = await _createVehicleLicense();
        await SubscriptionNotifier().fetchAndUpdateSubscription();

        if (licenseCreated) {
          _showSuccessDialog();
        } else {
          _showPartialSuccessDialog();
        }
      } else {
        _showErrorDialog("Subscription Failed",
            "Payment was successful but subscription activation failed. Please contact support.");
      }
    } catch (e) {
      print("Error processing payment: $e");
      _showErrorDialog("Payment Error", e.toString());
    } finally {
      setState(() {
        isProcessingPayment = false;
      });
    }
  }

  // Helper method to show success dialog
  void _showSuccessDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Success!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Payment processed successfully!'),
            const SizedBox(height: 8),
            Text('Subscription: ${widget.selectedPlan.name}'),
            Text('Vehicle: ${widget.vehicleTypeName}'),
            if (paymentTransactionId != null)
              Text('Transaction ID: $paymentTransactionId'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              if (widget.onSubscriptionCompleted != null) {
                widget.onSubscriptionCompleted!();
              }
              Navigator.of(context).pop(); // Go back to subscription screen
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  // Helper method to show partial success dialog
  void _showPartialSuccessDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Partial Success'),
          ],
        ),
        content: Text(
          'Your subscription was activated successfully, but there was an issue creating your ${widget.vehicleTypeName} license. Please contact support.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              if (widget.onSubscriptionCompleted != null) {
                widget.onSubscriptionCompleted!();
              }
              Navigator.of(context).pop(); // Go back to subscription screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Helper method to show error dialog
  void _showErrorDialog(String title, String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool> _createVehicleLicense() async {
    try {
      setState(() {
        isCreatingLicense = true;
      });

      final userId = await StorageService.getID();
      if (userId == null) {
        print("User ID is null, cannot create vehicle license");
        return false;
      }

      final licenseNumber =
          "LIC${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";

      print(
          "Creating vehicle license for userId: $userId, vehicleTypeId: ${widget.vehicleTypeId}");

      final response = await HttpService.post(
        'http://88.222.215.134:3000/exams/api/mock-exam/admin/user/$userId/licenses',
        body: {
          'vehicle_type_id': widget.vehicleTypeId,
          'license_number': licenseNumber,
        },
      );

      if (response['success'] == true) {
        print("Vehicle license created successfully: $licenseNumber");
        return true;
      } else {
        print("Failed to create vehicle license: ${response['error']}");
        return false;
      }
    } catch (e) {
      print("Error creating vehicle license: $e");
      return false;
    } finally {
      if (mounted) {
        setState(() {
          isCreatingLicense = false;
        });
      }
    }
  }

  Future<bool> _createSubscription() async {
    try {
      final userId = await StorageService.getID();
      if (userId == null) return false;

      final response = await SubscriptionService.createSubscription(
        userId: userId,
        planId: widget.selectedPlan.id,
        paymentMethod: "onepay",
        paymentDetails: {
          "transaction_id": paymentTransactionId,
          "onepay_transaction_id": onePayTransactionId,
        },
      );

      return response.success;
    } catch (e) {
      print("Error creating subscription: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: const Color(0xffD7ECFE),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan Details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Plan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.selectedPlan.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.selectedPlan.formattedPrice,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Color(0xff219EBC),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vehicle Type: ${widget.vehicleTypeName}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // License Information
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'What\'s Included',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Access to ${widget.vehicleTypeName} driving tests',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      '• Automatic ${widget.vehicleTypeName} license generation',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      '• Full access to all ${widget.selectedPlan.name} features',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Processing Status
            if (isProcessingPayment || isCreatingLicense)
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isCreatingLicense
                            ? 'Creating ${widget.vehicleTypeName} license...'
                            : 'Setting up payment...',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Payment Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (isProcessingPayment || isCreatingLicense)
                    ? null
                    : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff219EBC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  (isProcessingPayment || isCreatingLicense)
                      ? 'Processing...'
                      : 'Pay with OnePay',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// WebView widget for OnePay payment
class OnePayWebView extends StatefulWidget {
  final String paymentUrl;
  final String transactionId;
  final Function(bool success, String? transactionId) onPaymentResult;

  const OnePayWebView({
    super.key,
    required this.paymentUrl,
    required this.transactionId,
    required this.onPaymentResult,
  });

  @override
  _OnePayWebViewState createState() => _OnePayWebViewState();
}

class _OnePayWebViewState extends State<OnePayWebView> {
  late final WebViewController controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
            });

            // Check if the URL indicates payment completion
            if (url.contains('payment-success') || url.contains('success')) {
              widget.onPaymentResult(true, widget.transactionId);
              Navigator.pop(context);
            } else if (url.contains('payment-failed') ||
                url.contains('failed') ||
                url.contains('cancel')) {
              widget.onPaymentResult(false, null);
              Navigator.pop(context);
            }
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OnePay Payment'),
        backgroundColor: const Color(0xffD7ECFE),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            widget.onPaymentResult(false, null);
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
