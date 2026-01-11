import 'dart:io';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dialog_styles.dart';

/// FILE: dialog_widgets.dart
/// DESCRIZIONE: Raccolta di widget specifici utilizzati all'interno dei dialoghi complessi.
/// Include:
/// 1. InputDialogWidget: Un form dinamico per l'inserimento dati.
/// 2. Helper per Pickers.
/// 3. Componenti Profilo.

// --- INPUT DIALOG WIDGET ---
class InputDialogWidget extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> fields;
  final String confirmText;
  final String cancelText;
  final VoidCallback? onForgotPassword;

  const InputDialogWidget({
    super.key,
    required this.title,
    required this.fields,
    required this.confirmText,
    required this.cancelText,
    this.onForgotPassword,
  });

  @override
  State<InputDialogWidget> createState() => _InputDialogWidgetState();
}

class _InputDialogWidgetState extends State<InputDialogWidget> {
  late final List<TextEditingController> _controllers;
  late final List<ValueNotifier<bool>> _obscureStates;
  late final List<FocusNode> _focusNodes;

  Color get _textColor => DialogStyles.textColor(context);

  @override
  void initState() {
    super.initState();
    _controllers = widget.fields
        .map((f) => TextEditingController(text: f["initialValue"] ?? ""))
        .toList();
    _obscureStates = widget.fields
        .map((f) => ValueNotifier<bool>(f["obscureText"] ?? false))
        .toList();
    _focusNodes = List.generate(widget.fields.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var n in _obscureStates) {
      n.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onConfirm() {
    Navigator.pop(context, _controllers.map((c) => c.text).toList());
  }

  // Costruisce il TextField gestendo focus e visibilità password
  //
  Widget _buildTextField(int index) {
    final field = widget.fields[index];
    final isLast = index == widget.fields.length - 1;
    final hasPassword = field["obscureText"] == true;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12.h),
      child: ValueListenableBuilder<bool>(
        valueListenable: _obscureStates[index],
        builder: (_, hide, _) => Theme (
          data: Theme.of(context).copyWith(
            textSelectionTheme: TextSelectionThemeData(
              selectionHandleColor: AppColors.primary,
            )
          ),
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            cursorColor: AppColors.primary,
            obscureText: hide,
            keyboardType: field["keyboardType"] ?? TextInputType.text,
            textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
            onSubmitted: (_) {
              final scope = FocusScope.of(context);
              isLast
                  ? scope.unfocus()
                  : scope.requestFocus(_focusNodes[index + 1]);
            },
            style: TextStyle(fontSize: 15.sp),
            decoration: InputDecoration(
              labelText: field["label"],
              floatingLabelStyle: TextStyle(
                color: _textColor, 
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.primary
                ),
              ),
              prefixIcon: field["prefixIcon"] != null
                  ? Icon(field["prefixIcon"], size: 20.sp)
                  : null,
              hintText: field["hintText"],
              hintStyle: TextStyle(fontSize: 14.sp),
              suffixIcon: hasPassword
                  ? IconButton(
                      icon: Icon(
                        hide ? Icons.visibility_off : Icons.visibility,
                        color: _textColor,
                        size: 20.sp,
                      ),
                      onPressed: () => _obscureStates[index].value = !hide,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPassword() {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: widget.onForgotPassword,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size(0, 30.h),
          ),
          child: Text(
            loc.forgotPassword,
            style: TextStyle(
              color: _textColor,
              fontSize: 13.sp,
              decoration: TextDecoration.underline,
              decorationColor: _textColor,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(widget.fields.length, _buildTextField),
        if (widget.onForgotPassword != null) _buildForgotPassword(),
      ],
    );

    if (DialogStyles.isIOS) {
      return CupertinoAlertDialog(
        title: Text(widget.title, style: TextStyle(fontSize: 16.sp)),
        content: Padding(
          padding: EdgeInsets.only(top: 8.h),
          child: Material(color: Colors.transparent, child: content),
        ),
        actions: [
          DialogStyles.buildActionButton(
            context,
            widget.cancelText,
            _textColor,
            null,
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: _onConfirm,
            child: Text(
              widget.confirmText,
              style: TextStyle(color: _textColor, fontSize: 14.sp),
            ),
          ),
        ],
      );
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Text(
        widget.title,
        style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(child: content),
      actions: [
        DialogStyles.buildActionButton(
          context,
          widget.cancelText,
          _textColor,
          null,
        ),
        TextButton(
          onPressed: _onConfirm,
          child: Text(
            widget.confirmText,
            style: TextStyle(color: _textColor, fontSize: 14.sp),
          ),
        ),
      ],
    );
  }
}

// --- CHECKBOX ROW ---
class DialogCheckboxRow extends StatelessWidget {
  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  const DialogCheckboxRow({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Checkbox.adaptive(
            value: value,
            onChanged: (v) => onChanged(v ?? false),
            activeColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(label, style: TextStyle(fontSize: 13.sp)),
          ),
        ],
      ),
    );
  }
}

// --- PICKER HEADER ---
class PickerHeader extends StatelessWidget {
  final Color textColor;
  final VoidCallback? onCancel;
  final VoidCallback onConfirm;

  const PickerHeader({
    super.key,
    required this.textColor,
    this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onCancel ?? () => Navigator.pop(context, null),
            child: Text(
              loc.cancel,
              style: TextStyle(color: textColor, fontSize: 14.sp),
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onConfirm,
            child: Text(
              loc.ok,
              style: TextStyle(
                color: textColor,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- COMPONENTI PROFILO ---

// Header con avatar e dati utente
//
class ProfileHeader extends StatelessWidget {
  final User? user;
  final File? localAvatar;

  const ProfileHeader({
    super.key,
    required this.user,
    required this.localAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final txtColor = DialogStyles.textColor(context);
    final loc = AppLocalizations.of(context)!;

    return Column(
      children: [
        CircleAvatar(
          radius: 34.r,
          backgroundColor: AppColors.backgroundAvatar,
          backgroundImage: localAvatar != null
              ? FileImage(localAvatar!)
              : (user?.photoURL != null ? NetworkImage(user!.photoURL!) : null),
          child: localAvatar == null && user?.photoURL == null
              ? Icon(Icons.person, size: 50.sp, color: AppColors.avatar)
              : null,
        ),
        SizedBox(height: DialogStyles.isIOS ? 10.h : 12.h),
        Text(
          user?.displayName ?? loc.accountFallback,
          style: TextStyle(
            color: txtColor,
            fontWeight: FontWeight.bold,
            fontSize: DialogStyles.isIOS ? 15.sp : 17.sp,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          user?.email ?? "",
          style: TextStyle(
            color: txtColor,
            fontSize: DialogStyles.isIOS ? 13.sp : 15.sp,
          ),
        ),
      ],
    );
  }
}

class MaterialProfileTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  final VoidCallback onTap;

  const MaterialProfileTile({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      leading: Icon(icon, color: color ?? AppColors.primary, size: 24.sp),
      title: Text(
        text,
        style: TextStyle(
          fontSize: 16.sp,
          color: color ?? DialogStyles.textColor(context),
        ),
      ),
      onTap: onTap,
    );
  }
}