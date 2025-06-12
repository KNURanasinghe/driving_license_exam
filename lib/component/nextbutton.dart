import 'package:flutter/material.dart';

class NextButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final double widthPercentage;
  final bool isLastQuestion;

  const NextButton({
    super.key,
    this.onPressed,
    this.widthPercentage = 0.35, // Reduced from 0.4 to prevent overflow
    required this.isLastQuestion,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double baseFontSize = size.width * 0.04;
    final double baseIconSize = size.width * 0.045;
    final double basePadding = size.width * 0.03;

    final double buttonWidth = (size.width * widthPercentage).clamp(
      140.0,
      300.0,
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: size.height * 0.025,
        horizontal: size.width * 0.05,
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          width: buttonWidth,
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.circular(size.width * 0.0625),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: TextButton.icon(
              onPressed: onPressed,
              icon: Text(
                isLastQuestion ? 'Finish' : 'Next',
                style: TextStyle(
                  fontSize: baseFontSize,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              label: Icon(
                isLastQuestion ? Icons.done_all : Icons.arrow_forward_ios,
                color: Colors.white,
                size: baseIconSize,
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  vertical: basePadding,
                  horizontal: basePadding * 1.33,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
