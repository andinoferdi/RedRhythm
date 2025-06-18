import 'package:flutter/material.dart';

class SpotifySearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final FocusNode? focusNode;
  final bool autoFocus;
  final Widget? suffixIcon;
  final VoidCallback? onTap;
  final bool readOnly;

  const SpotifySearchBar({
    super.key,
    this.controller,
    this.hintText = 'Apa yang ingin kamu dengarkan?',
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autoFocus = false,
    this.suffixIcon,
    this.onTap,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autoFocus,
        readOnly: readOnly,
        onTap: onTap,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: 'DM Sans',
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Colors.grey,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'DM Sans',
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Colors.grey,
            size: 24,
          ),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: onChanged,
        onSubmitted: onSubmitted,
      ),
    );
  }
} 