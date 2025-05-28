import 'package:flutter/material.dart';
import 'package:driving_license_exam/services/http_service.dart';
import 'package:driving_license_exam/services/api_service.dart';
import 'package:driving_license_exam/services/subscription_service.dart';
import 'models/subscription_models.dart';

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
  String? paymentTransactionId; // Store transaction ID from payment gateway

  // Method to generate transaction ID in the required format
  String _generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 1000000000).toString().padLeft(9, '0');
    return "txn_$random";
  }

  // Method to handle Razorpay payment (placeholder - implement according to Razorpay documentation)
  Future<Map<String, dynamic>> _initiateRazorpayPayment() async {
    try {
      // This is a placeholder for Razorpay integration
      // In real implementation, you would:
      // 1. Initialize Razorpay with your API key
      // 2. Create payment options with amount, description, etc.
      // 3. Open Razorpay checkout
      // 4. Handle success/failure callbacks

      print(
          "Initiating Razorpay payment for ${widget.selectedPlan.formattedPrice}");

      // Simulate Razorpay payment process
      await Future.delayed(const Duration(seconds: 2));

      // Simulate successful payment response
      // In real implementation, this would come from Razorpay's success callback
      final transactionId = "txn_${DateTime.now().millisecondsSinceEpoch}";

      return {
        'success': true,
        'transaction_id': transactionId,
        'payment_method': 'razorpay',
        'amount': widget.selectedPlan.price,
      };

      /*
      // Real Razorpay implementation would look something like this:
      var options = {
        'key': 'your_razorpay_key',
        'amount': widget.selectedPlan.price * 100, // Amount in paise
        'name': 'Your App Name',
        'description': '${widget.selectedPlan.name} - ${widget.vehicleTypeName}',
        'prefill': {
          'contact': userPhone,
          'email': userEmail,
        },
        'theme': {
          'color': '#219EBC'
        }
      };
      
      _razorpay.open(options);
      // Handle success/failure in respective callback methods
      */
    } catch (e) {
      print("Razorpay payment error: $e");
      return {
        'success': false,
        'error': e.toString(),
      };
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

              // Call callback to refresh subscription screen
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
              Navigator.of(context).pop(); // Go back to subscription screen
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

      // Generate a license number (you might want to modify this logic)
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

        // Show success message to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${widget.vehicleTypeName} license created: $licenseNumber'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return true;
      } else {
        print("Failed to create vehicle license: ${response['error']}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Failed to create ${widget.vehicleTypeName} license'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return false;
      }
    } catch (e) {
      print("Error creating vehicle license: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating license: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    } finally {
      if (mounted) {
        setState(() {
          isCreatingLicense = false;
        });
      }
    }
  }

  // Your existing payment processing method - modify this
  Future<void> _processPayment() async {
    try {
      setState(() {
        isProcessingPayment = true;
      });

      // Your existing payment processing logic here
      // For example:
      // final paymentResult = await PaymentService.processPayment(widget.selectedPlan);

      // Simulate payment processing (replace with your actual payment logic)
      await Future.delayed(const Duration(seconds: 2));

      // If payment is successful, create the subscription
      bool subscriptionCreated = await _createSubscription();

      if (subscriptionCreated) {
        // After successful subscription creation, create vehicle license
        bool licenseCreated = await _createVehicleLicense();

        if (licenseCreated) {
          // Call the callback to refresh the subscription screen
          if (widget.onSubscriptionCompleted != null) {
            widget.onSubscriptionCompleted!();
          }

          // Show success message and navigate back
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Subscription activated successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );

            // Navigate back to subscription screen
            Navigator.of(context).pop();
          }
        } else {
          // License creation failed, but subscription was created
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Partial Success'),
                content: Text(
                    'Your subscription was activated successfully, but there was an issue creating your ${widget.vehicleTypeName} license. Please contact support.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context)
                          .pop(); // Go back to subscription screen
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        }
      } else {
        // Subscription creation failed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Failed to activate subscription. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print("Error processing payment: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isProcessingPayment = false;
        });
      }
    }
  }

  // Your existing subscription creation method (if you have one)
  Future<bool> _createSubscription() async {
    try {
      // Your existing subscription creation logic here
      // This should call your subscription API to create the subscription

      // Placeholder - replace with your actual subscription creation logic
      final userId = await StorageService.getID();
      if (userId == null) return false;
      final transactionId = _generateTransactionId();

      // Example API call (replace with your actual implementation)
      final response = await SubscriptionService.createSubscription(
        userId: userId,
        planId: widget.selectedPlan.id,
        paymentMethod: "razorpay",
        paymentDetails: {
          "transaction_id": transactionId, // Properly formatted transaction ID
        },
      );

      if (response.success) {
        // For now, simulating success
        await Future.delayed(const Duration(seconds: 1));
        return true;
      }
      return false;
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
                      : 'Complete Payment',
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
