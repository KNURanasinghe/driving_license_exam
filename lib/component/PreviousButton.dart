import 'package:flutter/material.dart';

class PreviousButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String buttonText;
  final double widthPercentage;

  const PreviousButton({
    super.key,
    this.onPressed,
    this.buttonText = "Previous",
    this.widthPercentage = 0.35, // Reduced from 0.4 to prevent overflow
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double baseFontSize = size.width * 0.035;
    final double baseIconSize = size.width * 0.035;
    final double basePadding = size.width * 0.03;

    final double buttonWidth = (size.width * widthPercentage).clamp(
      140.0,
      300.0,
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: size.height * 0.025,
        horizontal: size.width * 0.01,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: buttonWidth,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(size.width * 0.0625),
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
                fontSize: baseFontSize,
                fontWeight: FontWeight.w500,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
              padding: EdgeInsets.symmetric(
                vertical: basePadding,
                horizontal: basePadding * 1.33,
              ),
              alignment: Alignment.centerLeft,
            ),
          ),
        ),
      ),
    );
  }
}
