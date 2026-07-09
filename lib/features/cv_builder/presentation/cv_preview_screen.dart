import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../shared/widgets/status_view.dart';
import '../application/cv_builder_controller.dart';
import '../data/pdf/pdf_cv_generator.dart';
import 'cv_l10n.dart';

/// Renders the selected template as a real PDF (WYSIWYG) via `printing`'s
/// [PdfPreview], which also supplies the share / print / save toolbar.
class CvPreviewScreen extends ConsumerWidget {
  const CvPreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(cvBuilderControllerProvider);
    final lang = Localizations.localeOf(context).languageCode;
    final generator = ref.watch(cvPdfGeneratorProvider);
    final labels = cvLabels(l10n);

    if (state.data.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.cvPreviewTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              l10n.cvEmptyPreview,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.cvPreviewTitle)),
      body: PdfPreview(
        build: (format) => generator.generate(
          state.data,
          templateId: state.templateId,
          languageCode: lang,
          labels: labels,
        ),
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        pdfFileName: _fileName(state.data.fullName),
        loadingWidget: StatusView.loading(message: l10n.cvGenerating),
        onError: (context, error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(l10n.cvExportError, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }

  String _fileName(String fullName) {
    final base = fullName.trim().isEmpty ? 'CV' : fullName.trim();
    final safe = base.replaceAll(RegExp(r'[^A-Za-z0-9؀-ۿ ]'), '');
    return '${safe.replaceAll(' ', '_')}_CV.pdf';
  }
}
