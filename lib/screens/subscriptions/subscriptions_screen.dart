import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../models/account.dart';
import '../../models/subscription.dart';
import '../../providers/providers.dart';
import '../../utils/app_icon_registry.dart';
import '../../utils/errors/error_mapper.dart';
import '../../utils/subscription_payment_feedback.dart';
import '../../widgets/common/neo_page_components.dart';
import 'subscription_form_sheet.dart';

part 'subscriptions_screen_helpers.dart';

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = NeoTheme.of(context);
    final subscriptionsAsync = ref.watch(subscriptionsProvider);
    final accounts = ref.watch(accountsProvider).value ?? <Account>[];
    final totalCost = ref.watch(totalSubscriptionCostProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    return Scaffold(
      backgroundColor: palette.appBg,
      body: NeoPageBackground(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(subscriptionsProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    NeoLayout.screenPadding,
                    0,
                    NeoLayout.screenPadding,
                    AppSpacing.sm,
                  ),
                  child: _buildHeader(context),
                ),
              ),
              ...subscriptionsAsync.when(
                data: (subscriptions) {
                  final active =
                      subscriptions.where((s) => s.isActive).toList();
                  final paused =
                      subscriptions.where((s) => !s.isActive).toList();

                  return <Widget>[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: NeoLayout.screenPadding,
                        ),
                        child: _buildSummaryCard(
                          context,
                          totalCost,
                          active.length,
                          currencySymbol,
                        ),
                      ),
                    ),
                    if (active.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            NeoLayout.screenPadding,
                            NeoLayout.sectionGap,
                            NeoLayout.screenPadding,
                            AppSpacing.sm,
                          ),
                          child: _buildSectionHeading(
                            context,
                            title: 'Active',
                            count: active.length,
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: NeoLayout.screenPadding,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final sub = active[index];
                              return Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSpacing.sm),
                                child: _buildSubscriptionCard(
                                  context,
                                  ref,
                                  sub,
                                  currencySymbol,
                                  accounts,
                                ),
                              );
                            },
                            childCount: active.length,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            NeoLayout.screenPadding,
                            AppSpacing.sm,
                            NeoLayout.screenPadding,
                            0,
                          ),
                          child: _buildAddSubscriptionRow(
                            context: context,
                            onTap: () => _showAddSheet(context, ref),
                          ),
                        ),
                      ),
                    ],
                    if (active.isEmpty && subscriptions.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            NeoLayout.screenPadding,
                            NeoLayout.sectionGap,
                            NeoLayout.screenPadding,
                            0,
                          ),
                          child: _buildAddSubscriptionRow(
                            context: context,
                            onTap: () => _showAddSheet(context, ref),
                          ),
                        ),
                      ),
                    if (paused.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            NeoLayout.screenPadding,
                            NeoLayout.sectionGap,
                            NeoLayout.screenPadding,
                            AppSpacing.sm,
                          ),
                          child: _buildSectionHeading(
                            context,
                            title: 'Paused',
                            count: paused.length,
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: NeoLayout.screenPadding,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final sub = paused[index];
                              return Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSpacing.sm),
                                child: _buildSubscriptionCard(
                                  context,
                                  ref,
                                  sub,
                                  currencySymbol,
                                  accounts,
                                ),
                              );
                            },
                            childCount: paused.length,
                          ),
                        ),
                      ),
                    ],
                    if (subscriptions.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            NeoLayout.screenPadding,
                            NeoLayout.sectionGap,
                            NeoLayout.screenPadding,
                            0,
                          ),
                          child: _buildEmptyState(context, ref),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: AppSpacing.xl +
                            MediaQuery.paddingOf(context).bottom +
                            NeoLayout.bottomNavSafeBuffer,
                      ),
                    ),
                  ];
                },
                loading: () => [
                  const SliverToBoxAdapter(
                    child: SizedBox(
                      height: 360,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                ],
                error: (error, stack) => [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(NeoLayout.screenPadding),
                      child: _buildErrorState(
                        context,
                        ErrorMapper.toUserMessage(error, stackTrace: stack),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
