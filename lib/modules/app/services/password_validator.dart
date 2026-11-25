String? passwordValidationMessage(String? value) {
  final password = value ?? '';
  if (password.isEmpty) return 'Ingresa tu contraseña';
  if (RegExp(r'\s').hasMatch(password)) {
    return 'La contraseña no debe contener espacios';
  }
  if (password.runes.length < 8) return 'Usa al menos 8 caracteres';
  if (!RegExp(r'[A-ZÁÉÍÓÚÜÑ]').hasMatch(password)) {
    return 'Incluye al menos una letra mayúscula';
  }
  if (!RegExp(r'[a-záéíóúüñ]').hasMatch(password)) {
    return 'Incluye al menos una letra minúscula';
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
