// Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports - Models
import '../models/spaced_repetition_settings.dart';

// Project imports - Utils
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class SpacedRepetitionSettingsScreen extends ConsumerStatefulWidget {
  final SpacedRepetitionSettings? initialSettings;
  final Function(SpacedRepetitionSettings)? onSettingsChanged;

  const SpacedRepetitionSettingsScreen({
    super.key,
    this.initialSettings,
    this.onSettingsChanged,
  });

  @override
  ConsumerState<SpacedRepetitionSettingsScreen> createState() => _SpacedRepetitionSettingsScreenState();
}

class _SpacedRepetitionSettingsScreenState extends ConsumerState<SpacedRepetitionSettingsScreen> {
  late SpacedRepetitionSettings _settings;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings ?? SpacedRepetitionSettings();
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.appTheme;

    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: appTheme.appBarBackground,
        foregroundColor: appTheme.appBarIcon,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: appTheme.appBarIcon),
          onPressed: () {
            // Check if there are unsaved changes
            if (_hasChanges) {
              _showUnsavedChangesDialog();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          'Spaced Repetition Settings',
          style: TextStyle(
            color: appTheme.appBarIcon,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _saveSettings,
              child: Text(
                'Save',
                style: TextStyle(
                  color: appTheme.appBarIcon,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppConstants.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Presets Section
            _buildPresetsSection(),
            
            SizedBox(height: AppConstants.mediumSpacing),
            
            // Daily Limits Section
            _buildDailyLimitsSection(),
            
            SizedBox(height: AppConstants.mediumSpacing),
            
            // Interval Settings Section
            _buildIntervalSettingsSection(),
            
            SizedBox(height: AppConstants.mediumSpacing),
            
            // Ease Factor Settings Section
            _buildEaseFactorSection(),
            
            SizedBox(height: AppConstants.mediumSpacing),
            
            // Review Order Section
            _buildReviewOrderSection(),
            
            SizedBox(height: AppConstants.mediumSpacing),
            
            // Advanced Settings Section
            _buildAdvancedSettingsSection(),
            
            SizedBox(height: AppConstants.largeSpacing),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetsSection() {
    return _buildSection(
      title: 'Learning Style Presets',
      subtitle: 'Choose a preset that matches your learning style',
      child: Column(
        children: [
          _buildPresetButton('Beginner', 'Slower pace, more repetition', SpacedRepetitionPresets.beginner),
          SizedBox(height: 8),
          _buildPresetButton('Standard', 'Balanced learning pace', SpacedRepetitionPresets.standard),
          SizedBox(height: 8),
          _buildPresetButton('Intensive', 'Fast pace, frequent reviews', SpacedRepetitionPresets.intensive),
          SizedBox(height: 8),
          _buildPresetButton('Relaxed', 'Slower pace, longer intervals', SpacedRepetitionPresets.relaxed),
        ],
      ),
    );
  }

  Widget _buildPresetButton(String title, String subtitle, SpacedRepetitionSettings preset) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;
    final isSelected = _settings == preset;
    
    return InkWell(
      onTap: () => _applyPreset(preset),
      borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor.withValues(alpha: 0.1) : appTheme.cardBackground,
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          border: Border.all(
            color: isSelected ? theme.primaryColor : appTheme.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? theme.primaryColor : appTheme.secondaryText,
              size: 20,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: appTheme.primaryText,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: appTheme.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyLimitsSection() {
    return _buildSection(
      title: 'Daily Limits',
      subtitle: 'Control how many cards you study each day',
      child: Column(
        children: [
          _buildSliderSetting(
            'New Cards per Day',
            _settings.dailyNewCardsLimit.toDouble(),
            0,
            100,
            (value) => _updateSetting((s) => s.copyWith(dailyNewCardsLimit: value.round())),
          ),
          SizedBox(height: 16),
          _buildSliderSetting(
            'Review Cards per Day',
            _settings.dailyReviewLimit.toDouble(),
            0,
            200,
            (value) => _updateSetting((s) => s.copyWith(dailyReviewLimit: value.round())),
            helpText: '0 = unlimited',
          ),
        ],
      ),
    );
  }

  Widget _buildIntervalSettingsSection() {
    return _buildSection(
      title: 'Review Intervals',
      subtitle: 'How long to wait between reviews',
      child: Column(
        children: [
          _buildIntervalSetting('New Cards', _settings.newCardInterval, (value) => 
            _updateSetting((s) => s.copyWith(newCardInterval: value))),
          _buildIntervalSetting('Learning 1', _settings.learningInterval1, (value) => 
            _updateSetting((s) => s.copyWith(learningInterval1: value))),
          _buildIntervalSetting('Learning 2', _settings.learningInterval2, (value) => 
            _updateSetting((s) => s.copyWith(learningInterval2: value))),
          _buildIntervalSetting('Learning 3', _settings.learningInterval3, (value) => 
            _updateSetting((s) => s.copyWith(learningInterval3: value))),
          _buildIntervalSetting('Learning 4', _settings.learningInterval4, (value) => 
            _updateSetting((s) => s.copyWith(learningInterval4: value))),
          _buildIntervalSetting('Learning 5', _settings.learningInterval5, (value) => 
            _updateSetting((s) => s.copyWith(learningInterval5: value))),
          _buildIntervalSetting('Learning 6', _settings.learningInterval6, (value) => 
            _updateSetting((s) => s.copyWith(learningInterval6: value))),
          _buildIntervalSetting('Maximum', _settings.maxInterval, (value) => 
            _updateSetting((s) => s.copyWith(maxInterval: value))),
        ],
      ),
    );
  }

  Widget _buildEaseFactorSection() {
    return _buildSection(
      title: 'Ease Factor',
      subtitle: 'How difficulty affects review intervals',
      child: Column(
        children: [
          _buildSliderSetting(
            'Default Ease Factor',
            _settings.defaultEaseFactor,
            1.0,
            3.0,
            (value) => _updateSetting((s) => s.copyWith(defaultEaseFactor: value)),
            divisions: 20,
          ),
          SizedBox(height: 16),
          _buildSliderSetting(
            'Ease Factor Decrease',
            _settings.easeFactorDecrease,
            0.05,
            0.5,
            (value) => _updateSetting((s) => s.copyWith(easeFactorDecrease: value)),
            divisions: 45,
            helpText: 'How much to decrease on incorrect answers',
          ),
          SizedBox(height: 16),
          _buildSliderSetting(
            'Ease Factor Increase',
            _settings.easeFactorIncrease,
            0.05,
            0.5,
            (value) => _updateSetting((s) => s.copyWith(easeFactorIncrease: value)),
            divisions: 45,
            helpText: 'How much to increase on correct answers',
          ),
        ],
      ),
    );
  }

  Widget _buildReviewOrderSection() {
    return _buildSection(
      title: 'Review Order',
      subtitle: 'How to organize new cards and reviews',
      child: Column(
        children: ReviewOrder.values.map((order) {
          return RadioListTile<ReviewOrder>(
            title: Text(_getReviewOrderTitle(order)),
            subtitle: Text(_getReviewOrderSubtitle(order)),
            value: order,
            // ignore: deprecated_member_use
            groupValue: _settings.reviewOrder,
            // ignore: deprecated_member_use
            onChanged: (value) {
              if (value != null) {
                _updateSetting((s) => s.copyWith(reviewOrder: value));
              }
            },
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAdvancedSettingsSection() {
    final theme = Theme.of(context);
    return _buildSection(
      title: 'Advanced Settings',
      subtitle: 'Fine-tune the spaced repetition algorithm',
      child: Column(
        children: [
          SwitchListTile(
            title: Text('Graduated Intervals'),
            subtitle: Text('Use different intervals for learning stages'),
            value: _settings.enableGraduatedIntervals,
            onChanged: (value) => _updateSetting((s) => s.copyWith(enableGraduatedIntervals: value)),
            activeThumbColor: theme.primaryColor,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: Text('Ease Factor Adjustment'),
            subtitle: Text('Allow ease factor to change based on performance'),
            value: _settings.enableEaseFactorAdjustment,
            onChanged: (value) => _updateSetting((s) => s.copyWith(enableEaseFactorAdjustment: value)),
            activeThumbColor: theme.primaryColor,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: Text('Mix New and Review'),
            subtitle: Text('Interleave new cards with reviews'),
            value: _settings.mixNewAndReview,
            onChanged: (value) => _updateSetting((s) => s.copyWith(mixNewAndReview: value)),
            activeThumbColor: theme.primaryColor,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final appTheme = context.appTheme;
    return Container(
      padding: EdgeInsets.all(AppConstants.cardPadding),
      decoration: BoxDecoration(
        color: appTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        border: Border.all(color: appTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: appTheme.primaryText,
            ),
          ),
          SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: appTheme.secondaryText,
            ),
          ),
          SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSliderSetting(
    String title,
    double value,
    double min,
    double max,
    Function(double) onChanged, {
    int? divisions,
    String? helpText,
  }) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: appTheme.primaryText,
              ),
            ),
            Text(
              value.toStringAsFixed(divisions != null ? 2 : 0),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
        if (helpText != null) ...[
          SizedBox(height: 4),
          Text(
            helpText,
            style: TextStyle(
              fontSize: 11,
              color: appTheme.secondaryText,
            ),
          ),
        ],
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
          activeColor: theme.primaryColor,
          inactiveColor: appTheme.divider,
        ),
      ],
    );
  }

  Widget _buildIntervalSetting(String title, int value, Function(int) onChanged) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: appTheme.primaryText,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: value > 1 ? () => onChanged(value - 1) : null,
                icon: Icon(Icons.remove, size: 16),
                constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryColor,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => onChanged(value + 1),
                icon: Icon(Icons.add, size: 16),
                constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getReviewOrderTitle(ReviewOrder order) {
    switch (order) {
      case ReviewOrder.newCardsFirst:
        return 'New Cards First';
      case ReviewOrder.reviewsFirst:
        return 'Reviews First';
      case ReviewOrder.mixed:
        return 'Mixed';
    }
  }

  String _getReviewOrderSubtitle(ReviewOrder order) {
    switch (order) {
      case ReviewOrder.newCardsFirst:
        return 'Learn new cards before reviewing old ones';
      case ReviewOrder.reviewsFirst:
        return 'Review old cards before learning new ones';
      case ReviewOrder.mixed:
        return 'Mix new cards and reviews together';
    }
  }

  void _applyPreset(SpacedRepetitionSettings preset) {
    setState(() {
      _settings = preset;
      _hasChanges = true;
    });
  }

  void _updateSetting(SpacedRepetitionSettings Function(SpacedRepetitionSettings) updater) {
    setState(() {
      _settings = updater(_settings);
      _hasChanges = true;
    });
  }

  void _saveSettings() {
    final appTheme = context.appTheme;
    
    if (_settings.isValid()) {
      widget.onSettingsChanged?.call(_settings);
      setState(() {
        _hasChanges = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: appTheme.actionButtonBackground,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid settings. Please check your values.'),
          backgroundColor: appTheme.actionButtonBackground,
        ),
      );
    }
  }

  /// Show dialog when user tries to navigate away with unsaved changes
  void _showUnsavedChangesDialog() {
    final appTheme = context.appTheme;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: appTheme.surface,
          title: Text(
            'Unsaved Changes',
            style: TextStyle(
              color: appTheme.primaryText,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'You have unsaved changes. Do you want to save them before leaving?',
            style: TextStyle(color: appTheme.primaryText),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to settings
              },
              child: Text(
                'Discard',
                style: TextStyle(color: appTheme.secondaryText),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _saveSettings(); // Save and then go back
                Navigator.of(context).pop(); // Go back to settings
              },
              child: Text(
                'Save',
                style: TextStyle(color: appTheme.primaryBlue),
              ),
            ),
          ],
        );
      },
    );
  }
}
