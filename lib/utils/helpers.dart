import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1565C0);
  static const Color secondary = Color(0xFF0D47A1);
  static const Color accent = Color(0xFF42A5F5);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFE53935);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFB8C00);
}

class FormatHelper {
  FormatHelper._();

  static String formatCurrency(double amount) {
    final NumberFormat formatter = NumberFormat('#,##0', 'id_ID');
    return 'Rp ${formatter.format(amount.round())}';
  }

  static String formatDate(DateTime date) {
    final DateFormat formatter = DateFormat('dd MMM yyyy', 'id_ID');
    return formatter.format(date);
  }

  static String formatDateTime(DateTime date) {
    final DateFormat formatter = DateFormat('dd MMM yyyy HH:mm', 'id_ID');
    return formatter.format(date);
  }
}

class Validators {
  Validators._();

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nomor handphone tidak boleh kosong';
    }
    final String cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');
    if (!RegExp(r'^[0-9+]{10,15}$').hasMatch(cleaned)) {
      return 'Nomor handphone tidak valid';
    }
    return null;
  }

  static String? validateNumber(String? value, String fieldName, {double min = 0}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName tidak boleh kosong';
    }

    final cleaned = value.trim().replaceAll(RegExp(r'[^0-9,\.-]'), '');
    if (cleaned.isEmpty) {
      return '$fieldName harus berupa angka yang valid';
    }

    final parsed = double.tryParse(cleaned.replaceAll(',', '.'));
    if (parsed == null) {
      return '$fieldName harus berupa angka yang valid';
    }
    if (parsed < min) {
      return '$fieldName minimal $min';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email tidak boleh kosong';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Email tidak valid';
    }
    return null;
  }
}
