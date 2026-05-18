class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email requis';
    final regex = RegExp(r'^[\w.-]+@[\w.-]+\.\w+$');
    if (!regex.hasMatch(value)) return 'Email invalide';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.length < 6) return 'Minimum 6 caractères';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value != password) return 'Les mots de passe ne correspondent pas';
    return null;
  }

  static String? required(String? value, [String field = 'Ce champ']) {
    if (value == null || value.trim().isEmpty) return '$field est requis';
    return null;
  }
}
