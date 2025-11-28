// profile_avatar.dart
// -----------------------------------------------------------------------------
// 🖼️ WIDGET AVATAR PROFILO
// -----------------------------------------------------------------------------
// Gestisce:
// - Visualizzazione avatar utente
// - Bottone cambio foto (camera) con indicatore caricamento
// - Bottone rimuovi foto (icona "X")
// -----------------------------------------------------------------------------

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileAvatar extends StatefulWidget {
  // 🔧 Parametri
  final File? image; // Immagine avatar locale
  final bool isUploading; // Flag caricamento immagine
  final VoidCallback? onChangePicture; // Callback cambio foto
  final VoidCallback? onRemovePicture; // Callback rimuovi foto

  const ProfileAvatar({
    super.key,
    required this.image,
    required this.isUploading,
    this.onChangePicture,
    this.onRemovePicture,
  });

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // -----------------------------------------------------------------
          // 🎨 CERCHIO SFONDO PRIMARIO
          // -----------------------------------------------------------------
          Container(
            width: 125.r,
            height: 125.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.6),
            ),
          ),

          // -----------------------------------------------------------------
          // 🖼️ CERCHIO AVATAR + OMBRA
          // -----------------------------------------------------------------
          Container(
            width: 120.r,
            height: 120.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withValues(alpha: isDark ? 0.4 : 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: CircleAvatar(
              key: ValueKey(widget.image?.path ?? "default_avatar"),
              radius: 65.r,
              backgroundImage: widget.image != null
                  ? FileImage(widget.image!)
                  : null,
              backgroundColor: AppColors.backgroundAvatar,

              // ❌ Icona default se non c'è immagine
              child: widget.image == null
                  ? Icon(
                      Icons.person_rounded,
                      size: 70.r,
                      color: AppColors.avatar.withValues(alpha: 0.7),
                    )
                  : null,
            ),
          ),

          // -----------------------------------------------------------------
          // 📸 BOTTONE CAMBIO FOTO
          // -----------------------------------------------------------------
          Positioned(
            bottom: 5.h,
            right: 5.w,
            child: _buildActionButton(
              onTap: widget.isUploading ? null : widget.onChangePicture,
              color: AppColors.primary,
              child: widget.isUploading
                  ? SizedBox(
                      width: 18.w,
                      height: 18.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5.w,
                        color: AppColors.textLight,
                      ),
                    )
                  : Icon(
                      Icons.photo_camera_rounded,
                      color: AppColors.textLight,
                      size: 20.r,
                    ),
            ),
          ),

          // -----------------------------------------------------------------
          // ❌ BOTTONE RIMUOVI FOTO (se immagine presente)
          // -----------------------------------------------------------------
          if (widget.image != null)
            Positioned(
              bottom: 5.h,
              left: 5.w,
              child: _buildActionButton(
                onTap: widget.onRemovePicture,
                color: AppColors.delete,
                child: Icon(
                  Icons.close_rounded,
                  color: AppColors.textLight,
                  size: 20.r,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 🔘 FUNZIONE COMUNE PER CREARE I BOTTINI (camera / remove)
  // ---------------------------------------------------------------------------
  Widget _buildActionButton({
    required VoidCallback? onTap,
    required Color color,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 35.w,
        height: 35.h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withValues(alpha: 0.8)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}
