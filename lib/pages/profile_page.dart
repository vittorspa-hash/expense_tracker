// profile_page.dart
import 'package:expense_tracker/components/shared/custom_appbar.dart';
import 'package:expense_tracker/utils/fade_animation_mixin.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Importante

// Importa il tuo provider invece del service
import 'package:expense_tracker/providers/profile_provider.dart';

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
  @override
  TickerProvider get vsync => this;

  @override
  void initState() {
    super.initState();
    initFadeAnimation();

    // Caricamento iniziale dei dati tramite Provider (dopo il primo frame)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProfileProvider>().loadLocalData();
      }
    });
  }

  @override
  void dispose() {
    disposeFadeAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 🟢 ASCOLTIAMO IL PROVIDER
    // Usiamo Consumer così aggiorniamo solo questa parte se cambia qualcosa
    // oppure context.watch<ProfileProvider>() all'inizio del build.
    final provider = context.watch<ProfileProvider>();
    final user = provider.user;

    return Scaffold(
      appBar: CustomAppBar(
        title: "Profilo",
        icon: Icons.person_rounded,
        isDark: isDark,
      ),

      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => await provider.refreshUser(context),

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
                    key: ObjectKey(provider.localImage),
                    // Leggiamo i dati dallo stato del provider
                    image: provider.localImage,
                    isUploading: provider
                        .isLoading, // Usiamo isLoading generico o specifico se ne hai uno
                    // 📤 Cambia immagine
                    onChangePicture: () =>
                        provider.changeProfilePicture(context),

                    // ❌ Rimuovi immagine
                    onRemovePicture: () =>
                        provider.removeProfilePicture(context),
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
                        onPressed: () => provider.changeDisplayName(context),
                        isLoading: provider.isLoading,
                      ),

                      _buildDivider(isDark),

                      // 📧 Email
                      ProfileTile(
                        icon: Icons.email_outlined,
                        title: "Email",
                        value: user?.email,
                        tooltip: "Modifica email",
                        onPressed: () => provider.changeEmail(context),
                        isLoading: provider.isLoading,
                      ),

                      _buildDivider(isDark),

                      // 🔒 Password
                      ProfileTile(
                        icon: Icons.lock_outline_rounded,
                        title: "Password",
                        value: "••••••••••",
                        tooltip: "Modifica password",
                        onPressed: () => provider.changePassword(context),
                        isLoading: provider.isLoading,
                      ),

                      _buildDivider(isDark),

                      // 🆔 UID Firebase
                      ProfileTile(
                        icon: Icons.badge_outlined,
                        title: "ID utente",
                        value: user?.uid,
                        trailingIcon: Icons.content_copy_rounded,
                        tooltip: "Copia ID",
                        onPressed: () => provider.copyToClipboard(
                          context,
                          user?.uid,
                          message: "ID copiato negli appunti",
                        ),
                        isLoading: provider.isLoading,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                // -----------------------------------------------------------------
                // 🗑️ ELIMINA ACCOUNT
                // -----------------------------------------------------------------
                ElevatedButton(
                  onPressed: provider.isLoading
                      ? null
                      : () => provider.deleteAccount(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: isDark
                        ? AppColors.textDark
                        : AppColors.textLight,
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
                      if (provider.isLoading)
                        Padding(
                          padding: EdgeInsets.only(right: 12.w),
                          child: SizedBox(
                            width: 20.r,
                            height: 20.r,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textLight,
                            ),
                          ),
                        )
                      else ...[
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 22.r,
                          color: isDark
                              ? AppColors.textDark
                              : AppColors.textLight,
                        ),
                        SizedBox(width: 12.w),
                      ],
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
