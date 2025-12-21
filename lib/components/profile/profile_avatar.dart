import 'dart:io';
import 'package:flutter/material.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// FILE: profile_avatar.dart
/// DESCRIZIONE: Componente UI che visualizza l'immagine del profilo utente.
/// Utilizza uno Stack per sovrapporre l'immagine circolare, i pulsanti di azione
/// (Modifica/Rimuovi) e gli indicatori di stato (Caricamento).

class ProfileAvatar extends StatelessWidget {
  // --- PARAMETRI ---
  // File immagine locale (se presente), stato di upload e callback per le azioni.
  final File? image;
  final bool isUploading;
  final VoidCallback? onChangePicture;
  final VoidCallback? onRemovePicture;

  const ProfileAvatar({
    super.key,
    required this.image,
    required this.isUploading,
    this.onChangePicture,
    this.onRemovePicture,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // --- LAYOUT PRINCIPALE (STACK) ---
    // Sovrappone i vari elementi grafici:
    // 1. Sfondo decorativo.
    // 2. Contenitore Avatar (Immagine o Icona default).
    // 3. Pulsanti flottanti (Camera e Rimuovi).
    // 
    return Center(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Sfondo Cerchio (Decorativo)
          Container(
            width: 125.r,
            height: 125.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.6),
            ),
          ),

          // Cerchio Avatar (Immagine o Fallback)
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
              key: ValueKey(image?.path ?? "default_avatar"),
              radius: 65.r,
              backgroundImage: image != null ? FileImage(image!) : null,
              backgroundColor: AppColors.backgroundAvatar,
              child: image == null
                  ? Icon(
                      Icons.person_rounded,
                      size: 70.r,
                      color: AppColors.avatar.withValues(alpha: 0.7),
                    )
                  : null,
            ),
          ),

          // Pulsante Modifica (Camera)
          // Mostra uno spinner se è in corso un caricamento.
          Positioned(
            bottom: 5.h,
            right: 5.w,
            child: _buildActionButton(
              onTap: isUploading ? null : onChangePicture,
              color: AppColors.primary,
              child: isUploading
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

          // Pulsante Rimuovi (X)
          // Visibile solo se esiste un'immagine da rimuovere.
          if (image != null)
            Positioned(
              bottom: 5.h,
              left: 5.w,
              child: _buildActionButton(
                onTap: onRemovePicture,
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

  // --- WIDGET AUSILIARIO ---
  // Crea pulsanti circolari stilizzati con gradiente e ombra per mantenere coerenza visiva.
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