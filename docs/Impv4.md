# Impv4 — Home Page UI Polish (Premium Feel)

## Overview
This is a **UI-only polish pass**. No new features, no backend changes, no new files. You are adjusting colors, spacing, fonts, and card sizes to make the home screen look more premium.

**Files to modify (3 total):**
1. `lib/config/theme.dart`
2. `lib/screens/home/home_screen.dart`
3. `lib/widgets/budget/quick_stat_card.dart`

---

## Step 1: Add Teal Gradient to Theme

**File:** `lib/config/theme.dart`

### 1A. Add `tealDark` color constant

Find this block (around line 32):
```dart
  static const Color savings = Color(0xFF14B8A6);         // Teal
```

Add this line **directly below it**:
```dart
  static const Color tealDark = Color(0xFF0D9488);         // Teal 600
```

### 1B. Add `tealGradient`

Find this block (around line 52–56):
```dart
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  );
```

Add this **directly below `primaryGradient`**:
```dart
  static const LinearGradient tealGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
  );
```

**Do NOT remove `primaryGradient`** — it may be used elsewhere.

---

## Step 2: Polish the Home Screen

**File:** `lib/screens/home/home_screen.dart`

### 2A. Fix Greeting Header Spacing & Styling

Find `_buildGreetingHeader` method. Replace the entire method body with this:

```dart
  Widget _buildGreetingHeader(WidgetRef ref, AsyncValue<dynamic> profile) {
    final displayName = profile.value?.displayName ?? 'User';

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.md),
        child: Row(
          children: [
            // Profile avatar circle
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.savings,
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Greeting text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back',
                    style: AppTypography.bodySmall,
                  ),
                  Text(displayName, style: AppTypography.h2),
                ],
              ),
            ),
            // Notification bell icon
            IconButton(
              icon: const Icon(LucideIcons.bell, color: AppColors.textSecondary),
              onPressed: () {
                // Future: notifications screen
              },
            ),
          ],
        ),
      ),
    );
  }
```

**What changed from the old version:**
- `Padding` is now INSIDE `SafeArea` (was the other way around — caused top-of-screen cramping)
- Top padding changed from `0` → `AppSpacing.lg` (24px breathing room)
- Bottom padding changed from `AppSpacing.sm` → `AppSpacing.md` (16px)
- Avatar radius `24` → `20` (smaller, more refined)
- Avatar color `AppColors.primary` → `AppColors.savings` (teal)
- Avatar text font `20` → `16`
- "WELCOME BACK" → "Welcome back" with `AppTypography.bodySmall` (soft, not shouty)
- Name style `AppTypography.h3` → `AppTypography.h2` (bigger name = premium)
- **Removed** the search `IconButton` (placeholder with no functionality = clutter)

### 2B. Change Balance Card to Teal

In `_buildBalanceCard`, find this line:
```dart
        gradient: AppColors.primaryGradient,
```

Replace with:
```dart
        gradient: AppColors.tealGradient,
```

### 2C. Reduce Balance Amount Font Size

In `_buildBalanceCard`, find this block:
```dart
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
```

Change `fontSize: 36` → `fontSize: 32`.

### 2D. Change "Add New Transaction" Button Foreground Color

In `_buildBalanceCard`, find:
```dart
                foregroundColor: AppColors.primary,
```

Replace with:
```dart
                foregroundColor: AppColors.tealDark,
```

### 2E. Add Spacing After Balance Card

In the `build` method, find the Balance Card sliver (around line 50–52):
```dart
            // Balance Card
            SliverToBoxAdapter(
              child: _buildBalanceCard(ref, summary, currencySymbol),
            ),
```

Replace with:
```dart
            // Balance Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _buildBalanceCard(ref, summary, currencySymbol),
              ),
            ),
```

### 2F. Adjust Quick Stats Row Spacing

Find the Quick Stats sliver padding (around line 62–67):
```dart
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  0,
                ),
```

Change `AppSpacing.md` (second value, the top padding) → `AppSpacing.sm`:
```dart
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  0,
                ),
```

### 2G. Change "View All" Button Color in Upcoming Payments

In `_buildUpcomingPayments`, find:
```dart
                    child: Text(
                      'View All →',
                      style: TextStyle(color: AppColors.primary),
                    ),
```

Change `AppColors.primary` → `AppColors.savings`.

### 2H. Reduce Upcoming Payment Card Dimensions

In `_buildUpcomingPayments`, find:
```dart
            SizedBox(
              height: 160,
```

Change `height: 160` → `height: 140`.

In `_buildUpcomingCard`, find:
```dart
    return Container(
      width: 180,
```

Change `width: 180` → `width: 160`.

### 2I. Change Due Date Chip Colors

In `_buildUpcomingCard`, find the two places where `AppColors.primary` is used for the non-overdue state:

```dart
                  : AppColors.primary.withValues(alpha: 0.15),
```
Change to:
```dart
                  : AppColors.savings.withValues(alpha: 0.15),
```

And:
```dart
                  color: sub.isOverdue ? AppColors.error : AppColors.primary,
```
Change both instances to:
```dart
                  color: sub.isOverdue ? AppColors.error : AppColors.savings,
```

There are **3 occurrences** of `AppColors.primary` in `_buildUpcomingCard` to replace with `AppColors.savings`:
1. Background color of the chip (the `withValues(alpha: 0.15)` line)
2. Calendar icon color
3. Text color

### 2J. Change Subscriptions Preview "Add New" Button Color

In `_buildSubscriptionsPreview`, find the `TextButton.icon`:
```dart
              TextButton.icon(
                onPressed: () => _showAddSubscription(context),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Add New'),
              ),
```

Replace with:
```dart
              TextButton.icon(
                onPressed: () => _showAddSubscription(context),
                style: TextButton.styleFrom(foregroundColor: AppColors.savings),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Add New'),
              ),
```

### 2K. Add More Breathing Room Above Categories Title

Find the Categories Section Title sliver:
```dart
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
```

Change the top padding from `AppSpacing.md` → `AppSpacing.lg`:
```dart
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
```

---

## Step 3: Polish Quick Stat Cards

**File:** `lib/widgets/budget/quick_stat_card.dart`

Replace the `Container` inside `InkWell` (the entire decoration + child block) with this:

Find:
```dart
          child: Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizing.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
```

Replace with:
```dart
          child: Container(
            padding: AppSpacing.cardPaddingCompact,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizing.radiusLg),
              border: Border(
                left: BorderSide(color: color, width: 4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
```

**What changed:**
- Padding: `cardPadding` (16px all) → `cardPaddingCompact` (12px all) — more compact
- Added colored left border (4px) using the card's `color` prop — gives visual accent/distinction

Then find the amount text style:
```dart
                Text(
                  '$currencySymbol${actual.toStringAsFixed(0)}',
                  style: AppTypography.amountMedium,
                ),
```

Change `AppTypography.amountMedium` → `AppTypography.amountSmall`:
```dart
                Text(
                  '$currencySymbol${actual.toStringAsFixed(0)}',
                  style: AppTypography.amountSmall,
                ),
```

**Why:** `amountMedium` is 20px which looks oversized on a compact card. `amountSmall` is 16px — right-sized.

---

## Verification Checklist

After making all changes:

- [ ] Run the app — no compile errors
- [ ] Balance card shows **teal** gradient (not purple)
- [ ] Greeting area has breathing room at top (no cramping against status bar)
- [ ] "Welcome back" is lowercase/soft, name is large and bold
- [ ] Search icon is removed from header (only bell remains)
- [ ] Avatar circle is teal (not purple/indigo)
- [ ] "Add New Transaction" button text is teal (not purple)
- [ ] Quick stat cards have colored left border accent
- [ ] Quick stat cards feel compact (12px padding, 16px amount)
- [ ] Upcoming payment cards are smaller (160x140)
- [ ] "View All" and "Add New" buttons are teal-colored
- [ ] Due date chips on upcoming cards use teal (not purple)
- [ ] Categories section has more space above the "Categories" title
- [ ] Overall spacing between sections feels consistent and breathable

## What NOT To Do

- Do NOT delete `primaryGradient` from `theme.dart` — other screens may use it
- Do NOT change any logic, providers, or data flow — this is visual-only
- Do NOT add new files — only modify the 3 files listed
- Do NOT change the bottom navigation bar — it's fine as-is
- Do NOT modify any service, provider, or model files
- Do NOT change any routes
