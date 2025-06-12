import 'package:flutter/material.dart';

class PreviousButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String buttonText;
  final double widthPercentage;

  const PreviousButton({
    super.key,
    this.onPressed,
    this.buttonText = "Previous",
    this.widthPercentage = 0.4,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // ignore: unused_local_variable
    final double baseFontSize = size.width * 0.04;
    final double baseIconSize = size.width * 0.045;
    final double basePadding = size.width * 0.03;

    // Calculate button width with constraints for responsiveness
    final double buttonWidth = (size.width * widthPercentage).clamp(
      120.0, // Minimum width for small screens
      300.0, // Maximum width for large screens
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: size.height * 0.025,
        horizontal: size.width * 0.05,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: buttonWidth, // Use constrained width
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: TextButton.icon(
            onPressed: onPressed ?? () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios, size: baseIconSize),
            label: Text(
              buttonText,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
              padding: EdgeInsets.symmetric(
                vertical: basePadding,
                horizontal: basePadding * 1.33,
              ),
              alignment:
                  Alignment.centerLeft, // Align text and icon to the left
            ),
          ),
        ),
      ),
    );
  }
}
