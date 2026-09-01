import 'package:expense_tracker/components/auth/auth_header.dart';
import 'package:expense_tracker/components/auth/auth_tab_selector.dart';
import 'package:expense_tracker/components/auth/login_form.dart';
import 'package:expense_tracker/components/auth/register_form.dart';
import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/utils/fade_animation_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/config/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: auth_page.dart
/// DESCRIZIONE: Schermata principale di autenticazione. Gestisce la navigazione
/// tra Login e Registrazione tramite un TabController, offrendo un header
/// personalizzato e transizioni animate per un'esperienza utente fluida.

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage>
    with TickerProviderStateMixin, FadeAnimationMixin {
  // --- STATO E ANIMAZIONI ---
  late TabController _tabController;

  @override
  TickerProvider get vsync => this;

  // --- CICLO DI VITA ---
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    initFadeAnimation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    disposeFadeAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- BUILD UI ---
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = ref.watch(authFlowBusyProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        ),
        child: SafeArea(
          top: false,
          child: buildWithFadeAnimation(
            Column(
              children: [
                // Header statico: const, non si ricostruisce mai su isLoading.
                const AuthHeader(),

                SizedBox(height: 18.h),

                AuthTabSelector(
                  controller: _tabController,
                  isLoading: isLoading,
                ),

                SizedBox(height: 10.h),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: isLoading
                        ? const NeverScrollableScrollPhysics()
                        : const AlwaysScrollableScrollPhysics(),
                    children: const [LoginForm(), RegisterForm()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}