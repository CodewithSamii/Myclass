import 'package:flutter/cupertino.dart';
import '../../design_system/tokens.dart';
import 'primitives.dart';

/// Opens the standard About MyClass sheet with the required 3-line credits
void showAboutMyClassSheet(BuildContext context) {
  openSheet(
    context,
    Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About MyClass', style: context.type.headlineSmall),
          const SizedBox(height: 18),
          Text(
            'MyClass brings your academic day into focus.\n\nFrontend preview 1.0\nBuilt with Flutter. Campus data and people are illustrative.\n\nFor access problems, contact your class representative.',
            style: context.type.bodyLarge?.copyWith(
              height: 1.65,
              color: context.colors.secondary,
            ),
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MyClass v1.0.0',
                style: context.type.bodyMedium?.copyWith(
                  color: context.colors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '@2026 Saminul Islam Sami',
                style: context.type.bodyMedium?.copyWith(
                  color: context.colors.secondary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'All Rights Reserved',
                style: context.type.bodyMedium?.copyWith(
                  color: context.colors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            'Got it',
            icon: CupertinoIcons.checkmark,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    ),
  );
}
