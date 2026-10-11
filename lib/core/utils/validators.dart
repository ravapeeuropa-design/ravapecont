class Validators {
  static String? requiredText(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label es obligatorio.';
    }
    return null;
  }

  static String? postalCode(String? value) {
    if (value == null || !RegExp(r'^\d{5}$').hasMatch(value.trim())) {
      return 'El código postal debe tener 5 dígitos.';
    }
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
      return 'Introduce un email válido.';
    }
    return null;
  }
}
