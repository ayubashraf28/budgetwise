import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../models/category.dart';
import '../../models/item.dart';
import '../../models/transaction.dart';
import '../../providers/providers.dart';
import '../../utils/app_icon_registry.dart';
import '../../utils/errors/error_mapper.dart';
import '../../utils/transaction_display_utils.dart';
import '../../widgets/budget/budget_widgets.dart';
import '../../widgets/common/neo_page_components.dart';
import '../transactions/transaction_form_sheet.dart';
import 'category_form_sheet.dart';
import 'item_form_sheet.dart';

part 'category_detail_screen_year_mode.dart';
part 'category_detail_screen_content.dart';
part 'category_detail_screen_actions.dart';

class CategoryDetailScreen extends ConsumerWidget {
  final String categoryId;
  final bool yearMode;
  final String routePrefix;

  const CategoryDetailScreen({
    super.key,
    required this.categoryId,
    this.yearMode = false,
    this.routePrefix = '/budget',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencySymbol = ref.watch(currencySymbolProvider);

    if (yearMode) {
      return _buildYearMode(context, ref, currencySymbol);
    }

    final categoryAsync = ref.watch(categoryByIdProvider(categoryId));

    return categoryAsync.when(
      data: (category) {
        if (category == null) {
          return Scaffold(
            backgroundColor: NeoTheme.of(context).appBg,
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: const [NeoSettingsAppBarAction()],
            ),
            body: const Center(
              child: Text('Category not found'),
            ),
          );
        }
        return _buildScreen(context, ref, category, currencySymbol);
      },
      loading: () => Scaffold(
        backgroundColor: NeoTheme.of(context).appBg,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: const [NeoSettingsAppBarAction()],
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: NeoTheme.of(context).appBg,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: const [NeoSettingsAppBarAction()],
        ),
        body: Center(
          child: Text(
            ErrorMapper.toUserMessage(error, stackTrace: stack),
          ),
        ),
      ),
    );
  }
}
