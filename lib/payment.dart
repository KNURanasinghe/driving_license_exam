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

// Placeholder method to fetch user details (implement based on your backend)

  Future<Map<String, dynamic>> _createPaymentRequest() async {
    try {
      // Validate user ID
      final userId = await StorageService.getID();
      if (userId == null) {
        return {
          'success': false,
          'error': 'User not authenticated. Please log in.',
        };
      }

      // Fetch user details for the payment
      final userDetails = await _fetchUserDetails(userId);

      // Prepare payment data to send to backend
      final paymentData = {
        'user_id': userId,
        'plan_id': widget.selectedPlan.id,
        'vehicle_type_id': widget.vehicleTypeId,
        'vehicle_type_name': widget.vehicleTypeName,
        'amount': widget.selectedPlan.price,
        'currency': 'LKR',
        'payment_method': 'onepay',
        // Include user details for OnePay
        'customer_details': {
          'first_name': userDetails['success']
              ? userDetails['first_name'] ?? 'Customer'
              : 'Customer',
          'last_name': userDetails['success']
              ? userDetails['last_name'] ?? 'User'
              : 'User',
          'email': userDetails['success']
              ? userDetails['email'] ?? 'customer@example.com'
              : 'customer@example.com',
          'phone': userDetails['success']
              ? userDetails['phone_number'] ?? '+94771234567'
              : '+94771234567',
        }
      };

      print("Sending payment request to backend: $paymentData");

      // Send payment request to your backend
      final response = await HttpService.post(
        'http://88.222.215.134:3002/api/payment/debug-onepay-credentials',
        body: paymentData,
      );

      print("Backend payment response: $response");

      if (response['success'] == true) {
        return {
          'success': true,
          'payment_url': response['data']['payment_url'],
          'transaction_id': response['data']['transaction_id'],
          'reference': response['data']['reference'],
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Failed to create payment request',
        };
      }
    } catch (e) {
      print("Error creating payment request: $e");
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> _fetchUserDetails(String userId) async {
    try {
      print("Fetching user details for userId: $userId");

      final response = await HttpService.get(
        'http://88.222.215.134:3000/api/users/$userId',
      );

      print("User details response: $response");

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;

        // Extract and validate user data
        final firstName =
            data['name']?.toString().split(' ').first ?? 'Customer';
        final lastName =
            data['name']?.toString().split(' ').skip(1).join(' ') ?? '';
        final email = data['email']?.toString() ?? '';
        const phone = '+947171234123'; // Phone might not be in your user data

        return {
          'success': true,
          'first_name': firstName,
          'last_name': lastName.isNotEmpty ? lastName : 'User',
          'phone_number': phone,
          'email': email,
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
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // // Method to check payment status
  // Future<Map<String, dynamic>> _checkPaymentStatus(String transactionId) async {
  //   try {
  //     final requestBody = {
  //       "app_id": ONEPAY_APP_ID,
  //       "onepay_transaction_id": transactionId,
  //     };

  //     final response = await HttpService.post(
  //       '$ONEPAY_API_BASE/transaction/status/',
  //       headers: {
  //         'Authorization': ONEPAY_APP_TOKEN,
  //         'Content-Type': 'application/json',
  //       },
  //       body: requestBody,
  //     );

  //     if (response['status'] == 200) {
  //       final data = response['data'];
  //       return {
  //         'success': true,
  //         'paid': data['status'] == true,
  //         'amount': data['amount'],
  //         'paid_on': data['paid_on'],
  //       };
  //     } else {
  //       return {
  //         'success': false,
  //         'error': response['message'] ?? 'Failed to check payment status',
  //       };
  //     }
  //   } catch (e) {
  //     print("Error checking payment status: $e");
  //     return {
  //       'success': false,
  //       'error': e.toString(),
  //     };
  //   }
  // }

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
                paymentTransactionId = txnId;
              });

              // The backend will handle subscription creation via callback
              // Just refresh subscription data and show success
              await SubscriptionNotifier().fetchAndUpdateSubscription();

              // Small delay to ensure backend processing is complete
              await Future.delayed(const Duration(seconds: 2));

              _showSuccessDialog();
            } else {
              _showErrorDialog(
                  "Payment Failed", "Payment was not completed successfully.");
            }
          },
        ),
      ),
    );
  }

//   // Method to handle successful payment

// // Update your _handleSuccessfulPayment method to handle the backend response
//   Future<void> _handleSuccessfulPayment(String transactionId) async {
//     try {
//       setState(() {
//         isProcessingPayment = true;
//         paymentTransactionId = transactionId;
//       });

//       // The subscription and license creation is now handled by the backend
//       // We just need to refresh the subscription data and show success
//       await SubscriptionNotifier().fetchAndUpdateSubscription();

//       // Small delay to ensure backend processing is complete
//       await Future.delayed(const Duration(seconds: 2));

//       _showSuccessDialog();
//     } catch (e) {
//       _showErrorDialog("Error", "An error occurred: ${e.toString()}");
//     } finally {
//       setState(() {
//         isProcessingPayment = false;
//       });
//     }
//   }

  // Method to process payment with OnePay
  Future<void> _processPayment() async {
    try {
      setState(() {
        isProcessingPayment = true;
      });

      // Create payment request via backend
      final paymentRequest = await _createPaymentRequest();

      if (paymentRequest['success']) {
        // Open OnePay payment in WebView
        await _openOnePayPayment(
          paymentRequest['payment_url'],
          paymentRequest['transaction_id'],
        );
      } else {
        print('Error setting up payment: ${paymentRequest['error']}');
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

  // // Helper method to show partial success dialog
  // void _showPartialSuccessDialog() {
  //   if (!mounted) return;

  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (context) => AlertDialog(
  //       title: const Row(
  //         children: [
  //           Icon(Icons.warning, color: Colors.orange),
  //           SizedBox(width: 8),
  //           Text('Partial Success'),
  //         ],
  //       ),
  //       content: Text(
  //         'Your subscription was activated successfully, but there was an issue creating your ${widget.vehicleTypeName} license. Please contact support.',
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () {
  //             Navigator.of(context).pop(); // Close dialog
  //             if (widget.onSubscriptionCompleted != null) {
  //               widget.onSubscriptionCompleted!();
  //             }
  //             Navigator.of(context).pop(); // Go back to subscription screen
  //           },
  //           child: const Text('OK'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

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

  // Future<bool> _createVehicleLicense() async {
  //   try {
  //     setState(() {
  //       isCreatingLicense = true;
  //     });

  //     final userId = await StorageService.getID();
  //     if (userId == null) {
  //       print("User ID is null, cannot create vehicle license");
  //       return false;
  //     }

  //     final licenseNumber =
  //         "LIC${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";

  //     print(
  //         "Creating vehicle license for userId: $userId, vehicleTypeId: ${widget.vehicleTypeId}");

  //     final response = await HttpService.post(
  //       'http://88.222.215.134:3000/exams/api/mock-exam/admin/user/$userId/licenses',
  //       body: {
  //         'vehicle_type_id': widget.vehicleTypeId,
  //         'license_number': licenseNumber,
  //       },
  //     );

  //     if (response['success'] == true) {
  //       print("Vehicle license created successfully: $licenseNumber");
  //       return true;
  //     } else {
  //       print("Failed to create vehicle license: ${response['error']}");
  //       return false;
  //     }
  //   } catch (e) {
  //     print("Error creating vehicle license: $e");
  //     return false;
  //   } finally {
  //     if (mounted) {
  //       setState(() {
  //         isCreatingLicense = false;
  //       });
  //     }
  //   }
  // }

  // Future<bool> _createSubscription() async {
  //   try {
  //     final userId = await StorageService.getID();
  //     if (userId == null) return false;

  //     final response = await SubscriptionService.createSubscription(
  //       userId: userId,
  //       planId: widget.selectedPlan.id,
  //       paymentMethod: "onepay",
  //       paymentDetails: {
  //         "transaction_id": paymentTransactionId,
  //         "onepay_transaction_id": onePayTransactionId,
  //       },
  //     );

  //     return response.success;
  //   } catch (e) {
  //     print("Error creating subscription: $e");
  //     return false;
  //   }
  // }

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
// Replace your existing OnePayWebView class with this updated version

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
            debugPrint('WebView loading: $url');
          },
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
            });
            debugPrint('WebView finished loading: $url');

            // Check if the URL indicates payment completion from your backend
            if (url.contains('/payment/success')) {
              // Extract subscription_id and transaction_id from URL if needed
              final uri = Uri.parse(url);
              final subscriptionId = uri.queryParameters['subscription_id'];
              final transactionId = uri.queryParameters['transaction_id'];

              debugPrint(
                  'Payment successful: $transactionId, Subscription: $subscriptionId');
              widget.onPaymentResult(
                  true, transactionId ?? widget.transactionId);
              Navigator.pop(context);
            } else if (url.contains('/payment/failed')) {
              // Extract error information from URL if needed
              final uri = Uri.parse(url);
              final error = uri.queryParameters['error'] ?? 'Payment failed';

              debugPrint('Payment failed: $error');
              widget.onPaymentResult(false, null);
              Navigator.pop(context);
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
            // Don't automatically fail on resource errors, as they might be non-critical
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('Navigation request: ${request.url}');

            // Allow all navigation requests to proceed
            return NavigationDecision.navigate;
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
                    child: const Text('Continue Payment'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      widget.onPaymentResult(false, null);
                      Navigator.pop(context); // Close WebView
                    },
                    child: const Text('Cancel Payment'),
                  ),
                ],
              ),
            );
          },
        ),
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
                  Text('Loading payment page...'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
