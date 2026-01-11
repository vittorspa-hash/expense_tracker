import 'package:expense_tracker/components/auth/login_form.dart';
import 'package:expense_tracker/components/auth/register_form.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/utils/fade_animation_mixin.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: auth_page.dart
/// DESCRIZIONE: Schermata principale di autenticazione. Gestisce la navigazione
/// tra Login e Registrazione tramite un TabController, offrendo un header
/// personalizzato e transizioni animate per un'esperienza utente fluida.

class AuthPage extends StatefulWidget {
  static const route = "/";
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with TickerProviderStateMixin, FadeAnimationMixin {
  
  // --- STATO E ANIMAZIONI ---
  // Gestione del controller per i Tab e mixin per le animazioni di fade-in.
  late TabController _tabController;

  @override
  TickerProvider get vsync => this;

  // --- CICLO DI VITA ---
  // Inizializzazione e dismissione dei controller per evitare memory leak.
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
    // Configurazione dello scaffold con background dinamico (Light/Dark)
    // e struttura principale della pagina.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;

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
                // --- HEADER PERSONALIZZATO ---
                // Sezione superiore curva contenente il logo, il titolo dell'app
                // e una breve descrizione.
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
                          "assets/icons/money2.png",
                          width: 68.w,
                          height: 68.w,
                          fit: BoxFit.contain,
                        ),
                      ),

                      SizedBox(height: 16.h),

                      Text(
                        loc.authAppTitle,
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),

                      SizedBox(height: 8.h),

                      Text(
                        loc.authAppSubtitle,
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

                // --- SELETTORE TAB ---
                // Switch grafico per alternare tra le modalità di Accesso e Registrazione.
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

                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(FontAwesomeIcons.rightToBracket, size: 15.sp),
                            SizedBox(width: 8.w),
                            Text(loc.loginTab),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(FontAwesomeIcons.userPlus, size: 15.sp),
                            SizedBox(width: 8.w),
                            Text(loc.registerTab),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 10.h),

                // --- AREA CONTENUTO ---
                // TabBarView che renderizza i form specifici (Login/Register) nello spazio rimanente.
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: const [
                      LoginForm(),
                      RegisterForm(),
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