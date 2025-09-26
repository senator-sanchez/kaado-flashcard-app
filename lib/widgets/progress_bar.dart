// Flutter imports
import 'package:flutter/material.dart';

// Project imports - Constants
import '../constants/app_sizes.dart';

// Project imports - Utils
import '../utils/app_theme.dart';
import '../utils/constants.dart';

// Project imports - Widgets
import 'text_with_background.dart';

class ProgressBar extends StatelessWidget {
  final String progressText;
  final String scoreText;
  final double progressValue;
  final bool isCompleted;

  const ProgressBar({
    super.key,
    required this.progressText,
    required this.scoreText,
    required this.progressValue,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context); // Unused variable
    final appTheme = context.appTheme;
    
    return RepaintBoundary(
      child: Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      child: Column(
        children: [
          // Progress Text and Score Text on same row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Progress Text (left side)
              TextWithBackground(
                progressText,
                style: TextStyle(
                  fontSize: AppConstants.progressTextSize,
                  fontWeight: AppConstants.progressTextWeight,
                  color: appTheme.primaryText,
                ),
              ),
              // Score Text (right side)
              TextWithBackground(
                scoreText,
                style: TextStyle(
                  fontSize: AppConstants.progressScoreSize,
                  fontWeight: AppConstants.progressTextWeight,
                  color: appTheme.primaryText,
                ),
              ),
            ],
          ),
          
          SizedBox(height: AppConstants.progressBarSpacing),
          
          // Progress Bar
          Container(
            height: AppConstants.progressBarHeight,
            decoration: BoxDecoration(
              color: appTheme.surface,
              borderRadius: BorderRadius.circular(AppConstants.progressBarBorderRadius),
              border: Border.all(color: appTheme.divider, width: AppConstants.progressBarBorderWidth),
            ),
            child: Row(
              children: [
                // Blue progress bar that fills from left to right
                Expanded(
                  flex: (progressValue * AppConstants.progressMultiplier).round(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.amber : appTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(AppConstants.progressBarBorderRadius),
                    ),
                  ),
                ),
                // Remaining space
                Expanded(
                  flex: ((1 - progressValue) * AppConstants.progressMultiplier).round(),
                  child: SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}
