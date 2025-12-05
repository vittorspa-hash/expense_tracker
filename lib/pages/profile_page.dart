// profile_page.dart
// -----------------------------------------------------------------------------
// 👤 PAGINA PROFILO UTENTE
// -----------------------------------------------------------------------------
// Gestisce:
// - Visualizzazione avatar, nome, email, UID
// - Modifica dati utente tramite ProfileService
// - Cambio immagine profilo
// - Eliminazione account
// - Animazione fade-in iniziale
// -----------------------------------------------------------------------------

import 'package:expense_tracker/utils/fade_animation_mixin.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/services/profile_service.dart';
import 'package:expense_tracker/components/profile/profile_avatar.dart';
import 'package:expense_tracker/components/profile/profile_tile.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfilePage extends StatefulWidget {
  static const route = "/profile/page";
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin, FadeAnimationMixin {
  // 🔧 Service profilo (gestisce immagine, dati utente, update)
  final profileService = ProfileService();

  // 🔧 Getter per il vsync richiesto dal mixin
  @override
  TickerProvider get vsync => this;

  @override
  void initState() {
    super.initState();

    // 📷 Carica immagine profilo locale
    profileService.loadLocalProfileImage(_safeSetState);

    // 🎞️ Animazione fade-in iniziale
    initFadeAnimation();
  }

  @override
  void dispose() {
    disposeFadeAnimation(); // Rilascio memoria
    super.dispose();
  }

  // ⚡ Metodo sicuro per chiamare setState solo se il widget è ancora montato
  void _safeSetState() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // 👤 Utente corrente Firebase
    final user = profileService.user;

    // 🌗 Tema attuale
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // -------------------------------------------------------------------------
      // 🔝 APPBAR PROFILO
      // -------------------------------------------------------------------------
      appBar: AppBar(
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? AppColors.textDark : AppColors.textLight,),
        title: Text(
          "Profilo",
          style: TextStyle(
            color: isDark ? AppColors.textDark : AppColors.textLight,
            fontSize: 22.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(color: AppColors.primary),
        ),
      ),

      // -------------------------------------------------------------------------
      // 🔄 PULL-TO-REFRESH (aggiorna user Firebase)
      // -------------------------------------------------------------------------
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => profileService.refreshUser(context, _safeSetState),

        // -----------------------------------------------------------------------
        // 🎨 BACKGROUND + ANIMAZIONE
        // -----------------------------------------------------------------------
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.backgroundDark
                : AppColors.backgroundLight,
          ),
          child: buildWithFadeAnimation(
            ListView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              children: [
                // -----------------------------------------------------------------
                // 🖼️ AVATAR + CAMBIO FOTO
                // -----------------------------------------------------------------
                Container(
                  padding: EdgeInsets.symmetric(vertical: 20.h),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.cardDark.withValues(alpha: 0.3)
                        : AppColors.cardLight.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ProfileAvatar(
                    image: profileService.localImage,
                    isUploading: profileService.isUploading,

                    // 📤 Cambia immagine
                    onChangePicture: () =>
                        profileService.changeProfilePicture(context, _safeSetState),

                    // ❌ Rimuovi immagine
                    onRemovePicture: () =>
                        profileService.removeProfilePicture(context, _safeSetState),
                  ),
                ),

                SizedBox(height: 32.h),

                // -----------------------------------------------------------------
                // 📑 SEZIONE DATI PERSONALI
                // -----------------------------------------------------------------
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.cardDark.withValues(alpha: 0.5)
                        : AppColors.cardLight.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow.withValues(
                          alpha: isDark ? 0.3 : 0.08,
                        ),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // 👤 Nome
                      ProfileTile(
                        icon: Icons.person_outline_rounded,
                        title: "Nome",
                        value: user?.displayName,
                        tooltip: "Modifica nome",
                        onPressed: () =>
                            profileService.changeDisplayName(context),
                      ),

                      _buildDivider(isDark),

                      // 📧 Email
                      ProfileTile(
                        icon: Icons.email_outlined,
                        title: "Email",
                        value: user?.email,
                        tooltip: "Modifica email",
                        onPressed: () => profileService.changeEmail(
                          context,
                          () => profileService.refreshUser(
                            context,
                            _safeSetState,
                          ),
                        ),
                      ),

                      _buildDivider(isDark),

                      // 🔒 Password
                      ProfileTile(
                        icon: Icons.lock_outline_rounded,
                        title: "Password",
                        value: "••••••••••",
                        tooltip: "Modifica password",
                        onPressed: () => profileService.changePassword(context),
                      ),

                      _buildDivider(isDark),

                      // 🆔 UID Firebase
                      ProfileTile(
                        icon: Icons.badge_outlined,
                        title: "ID utente",
                        value: user?.uid,
                        trailingIcon: Icons.content_copy_rounded,
                        tooltip: "Copia ID",
                        onPressed: () => profileService.copyToClipboard(
                          context,
                          user?.uid,
                          message: "ID copiato negli appunti",
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                // -----------------------------------------------------------------
                // 🗑️ ELIMINA ACCOUNT
                // -----------------------------------------------------------------
                ElevatedButton(
                  onPressed: () => profileService.deleteAccount(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: isDark ? AppColors.textDark : AppColors.textLight,
                    elevation: 6,
                    shadowColor: AppColors.primary.withValues(alpha: 0.3),
                    minimumSize: Size(double.infinity, 50.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 22.r,
                        color: isDark ? AppColors.textDark : AppColors.textLight,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        "Elimina account",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------------
  // ➖ DIVIDER SEZIONI
  // -----------------------------------------------------------------------------
  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Divider(
        height: 1,
        thickness: 1,
        color: isDark
            ? AppColors.dividerDark.withValues(alpha: 0.3)
            : AppColors.dividerLight.withValues(alpha: 0.5),
      ),
    );
  }
}