String? passwordValidationMessage(String? value) {
  final password = (value ?? '').trim();
  if (password.isEmpty) return 'Ingresa tu contraseña';
  if (password.runes.length < 8) return 'Usa al menos 8 caracteres';
  if (!RegExp(r'[A-ZÁÉÍÓÚÜÑ]').hasMatch(password)) {
    return 'Incluye al menos una letra mayúscula';
  }
  if (!RegExp(r'\d').hasMatch(password)) {
    return 'Incluye al menos un número';
  }
  if (!RegExp(r'[^A-Za-zÁÉÍÓÚÜÑáéíóúüñ0-9\s]').hasMatch(password)) {
    return 'Incluye al menos un carácter especial';
  }
  return null;
}

bool isValidPassword(String value) => passwordValidationMessage(value) == null;
