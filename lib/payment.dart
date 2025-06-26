import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:driving_license_exam/services/http_service.dart';
import 'package:driving_license_exam/services/api_service.dart';
import 'package:driving_license_exam/services/subscription_service.dart';
import 'models/subscription_models.dart';
import 'providers/subscription_notifier.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

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

  // OnePay Configuration - Updated with your actual credentials
  static const String ONEPAY_APP_ID = "KO9S11908AD337D52818B";
  static const String ONEPAY_APP_TOKEN =
      "44009264bc2d58654668ed75e884aee44bd1541635b12c01fedc0149cb906f7b6314bbc23f167310.LZQQ11908AD337D5281BE";
  static const String ONEPAY_HASH_SALT = "ZP1G11908AD337D5281AB";
  static const String ONEPAY_CALLBACK_URL =
      "http://88.222.215.134:3000/sub/api/payment/onepay/callback";

  // Use production API URL as per documentation
  static const String ONEPAY_API_BASE = "https://api.onepay.lk/v3";

  // Method to generate transaction reference (10-21 characters as per OnePay requirements)
  String _generateTransactionReference() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999).toString().padLeft(6, '0');
    // Keep reference between 10-21 characters
    final reference =
        "DLA${timestamp.toString().substring(7)}${random.substring(0, 3)}";
    print("Generated reference: $reference (length: ${reference.length})");
    return reference;
  }

  // Method to generate hash for OnePay - Updated to match documentation
  String _generateOnePayHash(
      String appId, String currency, double amount, String hashSalt) {
    // According to OnePay docs: app_id + currency + amount + hash_salt
    final amountStr = amount.toStringAsFixed(2);
    final input = "$appId$currency$amountStr$hashSalt";
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString(); // Keep lowercase as per standard
  }

  // Method to create OnePay payment request - Updated to match API v3
  Future<Map<String, dynamic>> _createOnePayPaymentRequest() async {
    try {
      final reference = _generateTransactionReference();
      final amount = widget.selectedPlan.price;
      const currency = "LKR";

      // Generate hash according to OnePay documentation
      final hash = _generateOnePayHash(
          ONEPAY_APP_ID, currency, amount, ONEPAY_HASH_SALT);

      // Get user details
      final userId = await StorageService.getID();

      // Request body matching OnePay API v3 documentation exactly
      final requestBody = {
        "currency": currency,
        "app_id": ONEPAY_APP_ID,
        "hash": hash,
        "amount": amount, // Send as number, not string
        "reference": reference,
        "customer_first_name": "Test", // You should get real customer data
        "customer_last_name": "Customer",
        "customer_phone_number": "+94771234567",
        "customer_email": "test@example.com",
        "transaction_redirect_url": ONEPAY_CALLBACK_URL,
        "additionalData": json.encode({
          "subscription_plan_id": widget.selectedPlan.id,
          "vehicle_type_id": widget.vehicleTypeId,
          "user_id": userId,
        }),
      };

      print("Creating OnePay payment request: $requestBody");

      // Use exact endpoint from documentation
      final response = await HttpService.post(
        '$ONEPAY_API_BASE/checkout/link/',
        headers: {
          'Authorization':
              ONEPAY_APP_TOKEN, // Direct token, not Bearer according to docs
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      print("OnePay response: $response");

      // Handle response according to documentation structure
      if (response['status'] == 200) {
        final data = response['data'];
        return {
          'success': true,
          'payment_url': data['gateway']
              ['redirect_url'], // Exact path from docs
          'transaction_id':
              data['ipg_transaction_id'], // Exact field name from docs
          'reference': reference,
          'amount_details': data['amount'], // Store amount breakdown
        };
      } else {
        return {
          'success': false,
          'error': response['message'] ?? 'Failed to create payment request',
        };
      }
    } catch (e) {
      print("Error creating OnePay payment request: $e");
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Method to check payment status - Updated to match API v3
  Future<Map<String, dynamic>> _checkPaymentStatus(String transactionId) async {
    try {
      // Request body matching documentation
      final requestBody = {
        "app_id": ONEPAY_APP_ID,
        "onepay_transaction_id": transactionId, // Exact field name from docs
      };

      final response = await HttpService.post(
        '$ONEPAY_API_BASE/transaction/status/',
        headers: {
          'Authorization': ONEPAY_APP_TOKEN,
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      print("Payment status response: $response");

      if (response['status'] == 200) {
        final data = response['data'];
        return {
          'success': true,
          'paid': data['status'] == true, // Boolean status as per docs
          'amount': data['amount'],
          'paid_on': data['paid_on'],
          'transaction_id': data['ipg_transaction_id'],
          'currency': data['currency'],
          'transaction_request_datetime': data['transaction_request_datetime'],
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
          callbackUrl: ONEPAY_CALLBACK_URL,
          onPaymentResult: (success, txnId) async {
            if (success && txnId != null) {
              setState(() {
                onePayTransactionId = txnId;
              });

              // Add a small delay to ensure payment is processed
              await Future.delayed(const Duration(seconds: 3));

              // Verify payment status
              final statusResult = await _checkPaymentStatus(txnId);
              print("Payment verification result: $statusResult");

              if (statusResult['success'] && statusResult['paid']) {
                await _handleSuccessfulPayment(txnId);
              } else {
                _showErrorDialog("Payment Verification Failed",
                    "Payment could not be verified. Please contact support if payment was deducted.");
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
            Text('Payment Successful!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your subscription has been activated successfully!'),
            const SizedBox(height: 8),
            Text('Plan: ${widget.selectedPlan.name}'),
            Text('Vehicle Type: ${widget.vehicleTypeName}'),
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
          "payment_gateway": "onepay",
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
                            : 'Processing payment...',
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

// Updated WebView widget for OnePay payment
class OnePayWebView extends StatefulWidget {
  final String paymentUrl;
  final String transactionId;
  final String callbackUrl;
  final Function(bool success, String? transactionId) onPaymentResult;

  const OnePayWebView({
    super.key,
    required this.paymentUrl,
    required this.transactionId,
    required this.callbackUrl,
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
            print("WebView started loading: $url");
          },
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
            });
            print("WebView finished loading: $url");

            // Check if the URL indicates payment completion
            // OnePay might redirect to success/failure pages
            if (url.contains('success') ||
                url.contains('payment-success') ||
                url.contains('completed') ||
                url.contains('thank-you') ||
                url.contains(widget.callbackUrl)) {
              // Extract transaction ID from URL if possible
              String? extractedTxnId = _extractTransactionId(url);
              widget.onPaymentResult(
                  true, extractedTxnId ?? widget.transactionId);
              Navigator.pop(context);
            } else if (url.contains('failed') ||
                url.contains('payment-failed') ||
                url.contains('cancel') ||
                url.contains('error') ||
                url.contains('declined')) {
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

  String? _extractTransactionId(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.queryParameters['transaction_id'] ??
          uri.queryParameters['txn_id'] ??
          uri.queryParameters['ipg_transaction_id'] ??
          uri.queryParameters['id'];
    } catch (e) {
      print("Error extracting transaction ID: $e");
      return null;
    }
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
            // Show confirmation dialog before canceling
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Cancel Payment'),
                content:
                    const Text('Are you sure you want to cancel the payment?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('No'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      widget.onPaymentResult(false, null);
                      Navigator.pop(context); // Close WebView
                    },
                    child: const Text('Yes'),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              controller.reload();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading OnePay payment page...'),
                  SizedBox(height: 8),
                  Text(
                      'Please wait while we redirect you to secure payment gateway'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
