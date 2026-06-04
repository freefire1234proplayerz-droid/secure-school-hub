import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';

class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final locale = context.watch<LocaleProvider>().locale;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          loc.language,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: SegmentedButton<String>(
            style: ButtonStyle(
              minimumSize: WidgetStateProperty.all(const Size(70, 40)),
              padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            ),
            segments: [
              ButtonSegment(
                value: 'en',
                label: Text(loc.english),
              ),
              ButtonSegment(
                value: 'hi',
                label: Text(loc.hindi),
              ),
            ],
            selected: {locale.languageCode},
            onSelectionChanged: (Set<String> _) {
              context.read<LocaleProvider>().toggleLocale();
            },
          ),
        ),
      ],
    );
  }
}
