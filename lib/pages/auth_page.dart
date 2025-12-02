// auth_page.dart
// -----------------------------------------------------------------------------
// 🧭 Schermata di Autenticazione dell’app
//
// Gestisce il passaggio tra Login e Registrazione tramite TabBar e animazioni,
// mostrando un header moderno e transizioni fluide.
// Integra i form di accesso e registrazione tramite LoginForm e RegisterForm.
// -----------------------------------------------------------------------------

import 'package:expense_tracker/components/auth/login_form.dart';
import 'package:expense_tracker/components/auth/register_form.dart';
import 'package:expense_tracker/utils/fade_animation_mixin.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AuthPage extends StatefulWidget {
  static const route = "/";
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with TickerProviderStateMixin, FadeAnimationMixin {
  // Controller per la TabBar (Login / Registrazione)
  late TabController _tabController;

  // Service che gestisce tutta la logica di autenticazione
  final _authService = AuthService();

  // Getter per il vsync richiesto dal mixin
  @override
  TickerProvider get vsync => this;

  @override
  void initState() {
    super.initState();

    // TabBar: 2 tab → Login e Registrazione
    _tabController = TabController(length: 2, vsync: this);

    // Inizializzazione animazione fade-in
    initFadeAnimation();
  }

  @override
  void dispose() {
    // Libera le animazioni quando la pagina viene chiusa
    _tabController.dispose();
    disposeFadeAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Rileva tema scuro/chiaro
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        // Sfondo dinamico basato sul tema
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        ),
        child: SafeArea(
          top: false, // evita spazio sopra per header personalizzato
          child: buildWithFadeAnimation(
            Column(
              children: [
                // -----------------------------------------------------------------
                // 🌈 HEADER SUPERIORE CON LOGO E TITOLO
                // -----------------------------------------------------------------
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 20.h,
                    bottom: 30.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32.r),
                      bottomRight: Radius.circular(32.r),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Logo circolare semi-trasparente
                      Container(
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          color: AppColors.avatar.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.avatar.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Image.asset(
                          "assets/icons/money.png",
                          width: 68.w,
                          height: 68.w,
                          fit: BoxFit.contain,
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // Titolo principale
                      Text(
                        "Expense Tracker",
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),

                      SizedBox(height: 8.h),

                      // Sottotitolo descrittivo
                      Text(
                        "Gestisci le tue spese in modo semplice",
                        style: TextStyle(
                          color: AppColors.textLight.withValues(alpha: 0.9),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 18.h),

                // -----------------------------------------------------------------
                // 🔀 TABBAR "Accedi / Registrati"
                // -----------------------------------------------------------------
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20.w),
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow.withValues(
                          alpha: isDark ? 0.3 : 0.08,
                        ),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: AppColors.textLight,
                    unselectedLabelColor: isDark
                        ? AppColors.greyDark
                        : AppColors.greyLight,
                    labelStyle: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),

                    // Bottoni tab
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(FontAwesomeIcons.rightToBracket, size: 15.sp),
                            SizedBox(width: 8.w),
                            const Text("Accedi"),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(FontAwesomeIcons.userPlus, size: 15.sp),
                            SizedBox(width: 8.w),
                            const Text("Registrati"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 10.h),

                // -----------------------------------------------------------------
                // 📝 CONTENUTO DEI TAB: Form di Login & Registrazione
                // -----------------------------------------------------------------
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Form di login
                      LoginForm(authService: _authService),

                      // Form di registrazione
                      RegisterForm(authService: _authService),
                    ],
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
