import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/services/cv_repository/cv_document.dart';
import '../../../core/services/cv_repository/cv_repository.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/search_field.dart';
import '../../../shared/widgets/status_view.dart';
import '../../auth/presentation/widgets/auth_error.dart';
import '../application/cv_actions_controller.dart';
import '../application/cv_library_controller.dart';
import '../domain/cv_sort.dart';
import 'cv_repository_l10n.dart';
import 'widgets/cv_card.dart';
import 'widgets/cv_name_dialog.dart';

/// The CV repository ("My CVs"): search / filter / sort, create + import, and
/// per-CV lifecycle actions.
class CvLibraryScreen extends ConsumerStatefulWidget {
  const CvLibraryScreen({super.key});

  @override
  ConsumerState<CvLibraryScreen> createState() => _CvLibraryScreenState();
}

class _CvLibraryScreenState extends ConsumerState<CvLibraryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cvsAsync = ref.watch(cvDocumentsProvider);
    final visible = ref.watch(visibleCvsProvider);
    final libState = ref.watch(cvLibraryControllerProvider);
    final importing =
        ref.watch(cvActionsControllerProvider.select((s) => s.importing));

    // Surface action failures (e.g. last-active-CV protection).
    ref.listen(cvActionsControllerProvider.select((s) => s.failure), (_, f) {
      if (f != null) {
        showAuthSnack(context, cvActionFailureMessage(l10n, f), isError: true);
        ref.read(cvActionsControllerProvider.notifier).clearFailure();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cvLibraryTitle),
        actions: [
          PopupMenuButton<CvSortOption>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: l10n.cvSort,
            initialValue: libState.sort,
            onSelected: (s) =>
                ref.read(cvLibraryControllerProvider.notifier).setSort(s),
            itemBuilder: (_) => [
              _sortItem(CvSortOption.updatedDesc, l10n.cvSortUpdated),
              _sortItem(CvSortOption.nameAsc, l10n.cvSortName),
              _sortItem(CvSortOption.atsDesc, l10n.cvSortAts),
              _sortItem(CvSortOption.lastUsedDesc, l10n.cvSortLastUsed),
            ],
          ),
        ],
        bottom: importing
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(minHeight: 3),
              )
            : null,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: importing ? null : () => _showCreateOrImport(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.cvCreate),
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(context.horizontalGutter,
                    AppSpacing.md, context.horizontalGutter, AppSpacing.sm),
                child: SearchField(
                  controller: _searchController,
                  hintText: l10n.cvSearchHint,
                  onChanged: (v) =>
                      ref.read(cvLibraryControllerProvider.notifier).setQuery(v),
                ),
              ),
              _FilterChips(current: libState.filter),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: cvsAsync.isLoading
                    ? const StatusView.loading()
                    : visible.isEmpty
                        ? _empty(context, l10n, libState.filter)
                        : ListView.separated(
                            padding: EdgeInsets.fromLTRB(
                                context.horizontalGutter,
                                AppSpacing.xs,
                                context.horizontalGutter,
                                AppSpacing.xxl),
                            itemCount: visible.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (_, i) {
                              final cv = visible[i];
                              return CvCard(
                                cv: cv,
                                onTap: () => context.pushNamed(
                                  RouteNames.cvDetail,
                                  pathParameters: {'id': cv.id},
                                ),
                                onMenu: () => _showActions(context, cv),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<CvSortOption> _sortItem(CvSortOption v, String label) =>
      PopupMenuItem(value: v, child: Text(label));

  Widget _empty(
      BuildContext context, AppLocalizations l10n, CvStatusFilter filter) {
    if (filter == CvStatusFilter.archived) {
      return StatusView.empty(
        icon: Icons.inventory_2_outlined,
        title: l10n.cvArchivedEmptyTitle,
        message: l10n.cvArchivedEmptyBody,
      );
    }
    return StatusView.empty(
      icon: Icons.description_outlined,
      title: l10n.cvEmptyTitle,
      message: l10n.cvEmptyBody,
      action: PrimaryButton(
        label: l10n.cvCreate,
        icon: Icons.add_rounded,
        onPressed: () => _create(context),
      ),
    );
  }

  // --- Create / Import ------------------------------------------------------

  void _showCreateOrImport(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.note_add_outlined),
              title: Text(l10n.cvCreate),
              onTap: () {
                Navigator.of(sheet).pop();
                _create(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file_outlined),
              title: Text(l10n.cvImport),
              onTap: () {
                Navigator.of(sheet).pop();
                _import(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _create(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final result = await showCvNameDialog(
      context,
      title: l10n.cvCreateTitle,
      initialName: l10n.cvDefaultNewName,
    );
    if (result == null) return;
    final controller = ref.read(cvActionsControllerProvider.notifier);
    final cv = await controller.createFromProfile(name: result.name);
    if (cv != null && result.tags.isNotEmpty) {
      await controller.updateTags(cv, result.tags);
    }
    if (cv != null && context.mounted) {
      context.pushNamed(RouteNames.cvDetail, pathParameters: {'id': cv.id});
    }
  }

  Future<void> _import(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(cvActionsControllerProvider.notifier);
    final outcome = await controller.pickAndImport();
    if (!context.mounted) return;
    switch (outcome.kind) {
      case ImportKind.created:
        showAuthSnack(context, l10n.cvImportedDone);
        final cv = outcome.created;
        if (cv != null) {
          context.pushNamed(RouteNames.cvDetail, pathParameters: {'id': cv.id});
        }
      case ImportKind.duplicate:
        await _resolveDuplicate(context, outcome.existing!, outcome.pending!);
      case ImportKind.failed:
        showAuthSnack(context, cvActionFailureMessage(l10n, outcome.failure!),
            isError: true);
      case ImportKind.cancelled:
        break;
    }
  }

  Future<void> _resolveDuplicate(
    BuildContext context,
    CvDocument existing,
    PendingImport pending,
  ) async {
    final l10n = AppLocalizations.of(context);
    final choice = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(l10n.cvImportDuplicateTitle),
        content: Text(l10n.cvImportDuplicateBody(existing.name)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(d).pop('cancel'),
              child: Text(l10n.cancel)),
          TextButton(
              onPressed: () => Navigator.of(d).pop('replace'),
              child: Text(l10n.cvImportReplace)),
          FilledButton(
              onPressed: () => Navigator.of(d).pop('new'),
              child: Text(l10n.cvImportAsNew)),
        ],
      ),
    );
    if (!context.mounted || choice == null || choice == 'cancel') return;
    final controller = ref.read(cvActionsControllerProvider.notifier);
    if (choice == 'replace') {
      await controller.confirmImportReplace(existing, pending);
      if (context.mounted) showAuthSnack(context, l10n.cvImportReplacedDone);
    } else {
      final cv = await controller.confirmImportAsNew(pending);
      if (context.mounted) {
        showAuthSnack(context, l10n.cvImportedDone);
        if (cv != null) {
          context.pushNamed(RouteNames.cvDetail, pathParameters: {'id': cv.id});
        }
      }
    }
  }

  // --- Per-CV actions -------------------------------------------------------

  void _showActions(BuildContext context, CvDocument cv) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(cvActionsControllerProvider.notifier);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) {
        void act(VoidCallback fn) {
          Navigator.of(sheet).pop();
          fn();
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_document),
                title: Text(l10n.cvActionOpen),
                onTap: () => act(() => context.pushNamed(
                      RouteNames.cvBuilder,
                      extra: cv.id,
                    )),
              ),
              ListTile(
                leading: const Icon(Icons.drive_file_rename_outline),
                title: Text(l10n.cvActionRename),
                onTap: () => act(() => _rename(context, cv)),
              ),
              ListTile(
                leading: const Icon(Icons.sell_outlined),
                title: Text(l10n.cvActionEditTags),
                onTap: () => act(() => _editTags(context, cv)),
              ),
              ListTile(
                leading: const Icon(Icons.copy_all_outlined),
                title: Text(l10n.cvActionDuplicate),
                onTap: () => act(() => controller.duplicate(cv,
                    copyLabel: l10n.cvCopySuffix)),
              ),
              if (cv.isActive && !cv.isDefault)
                ListTile(
                  leading: const Icon(Icons.star_outline_rounded),
                  title: Text(l10n.cvActionSetDefault),
                  onTap: () => act(() async {
                    await controller.setDefault(cv);
                    if (context.mounted) {
                      showAuthSnack(context, l10n.cvDefaultSet);
                    }
                  }),
                ),
              if (cv.isActive)
                ListTile(
                  leading: const Icon(Icons.archive_outlined),
                  title: Text(l10n.cvActionArchive),
                  onTap: () => act(() => _confirmArchive(context, cv)),
                )
              else
                ListTile(
                  leading: const Icon(Icons.unarchive_outlined),
                  title: Text(l10n.cvActionRestore),
                  onTap: () => act(() async {
                    await controller.restore(cv);
                    if (context.mounted) {
                      showAuthSnack(context, l10n.cvRestoredDone);
                    }
                  }),
                ),
              ListTile(
                leading: Icon(Icons.delete_outline_rounded,
                    color: Theme.of(context).colorScheme.error),
                title: Text(l10n.cvActionDelete,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
                onTap: () => act(() => _confirmDelete(context, cv)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _rename(BuildContext context, CvDocument cv) async {
    final l10n = AppLocalizations.of(context);
    final result = await showCvNameDialog(context,
        title: l10n.cvRenameTitle, initialName: cv.name, withTags: false);
    if (result != null) {
      await ref.read(cvActionsControllerProvider.notifier).rename(cv, result.name);
    }
  }

  Future<void> _editTags(BuildContext context, CvDocument cv) async {
    final l10n = AppLocalizations.of(context);
    final result = await showCvNameDialog(context,
        title: l10n.cvEditTagsTitle, initialName: cv.name, initialTags: cv.tags);
    if (result != null) {
      await ref
          .read(cvActionsControllerProvider.notifier)
          .updateTags(cv, result.tags);
    }
  }

  Future<void> _confirmArchive(BuildContext context, CvDocument cv) async {
    final l10n = AppLocalizations.of(context);
    final ok = await _confirm(context, l10n.cvArchiveTitle, l10n.cvArchiveBody,
        l10n.cvActionArchive);
    if (ok != true) return;
    final done = await ref.read(cvActionsControllerProvider.notifier).archive(cv);
    if (done && context.mounted) showAuthSnack(context, l10n.cvArchivedDone);
  }

  Future<void> _confirmDelete(BuildContext context, CvDocument cv) async {
    final l10n = AppLocalizations.of(context);
    final ok = await _confirm(
        context, l10n.cvDeleteTitle, l10n.cvDeleteBody, l10n.cvActionDelete,
        destructive: true);
    if (ok != true) return;
    final done = await ref.read(cvActionsControllerProvider.notifier).delete(cv);
    if (done && context.mounted) showAuthSnack(context, l10n.cvDeletedDone);
  }

  Future<bool?> _confirm(
    BuildContext context,
    String title,
    String body,
    String confirmLabel, {
    bool destructive = false,
  }) {
    final l10n = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(d).pop(false),
              child: Text(l10n.cancel)),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error)
                : null,
            onPressed: () => Navigator.of(d).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}

class _FilterChips extends ConsumerWidget {
  const _FilterChips({required this.current});
  final CvStatusFilter current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(cvLibraryControllerProvider.notifier);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.horizontalGutter),
        child: Wrap(
          spacing: AppSpacing.sm,
          children: [
            ChoiceChip(
              label: Text(l10n.cvFilterActive),
              selected: current == CvStatusFilter.active,
              onSelected: (_) => notifier.setFilter(CvStatusFilter.active),
            ),
            ChoiceChip(
              label: Text(l10n.cvFilterArchived),
              selected: current == CvStatusFilter.archived,
              onSelected: (_) => notifier.setFilter(CvStatusFilter.archived),
            ),
          ],
        ),
      ),
    );
  }
}
