/// Classe com validadores de formulário
class Validators {
  /// Valida email
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email é obrigatório';
    }
    if (!isValidEmail(value)) {
      return 'Email inválido';
    }
    return null;
  }

  /// Valida senha
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Senha é obrigatória';
    }
    if (value.length < 6) {
      return 'Senha deve ter no mínimo 6 caracteres';
    }
    return null;
  }

  /// Valida telefone
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Telefone é obrigatório';
    }
    if (!isValidPhone(value)) {
      return 'Telefone inválido';
    }
    return null;
  }

  /// Valida CPF
  static String? cpf(String? value) {
    if (value == null || value.isEmpty) {
      return 'CPF é obrigatório';
    }
    if (!isValidCPF(value)) {
      return 'CPF inválido';
    }
    return null;
  }

  /// Valida campo obrigatório
  static String? required(String? value, [String fieldName = 'Campo']) {
    if (value == null || value.isEmpty) {
      return '$fieldName é obrigatório';
    }
    return null;
  }
}

/// Funções de validação
bool isValidEmail(String email) {
  final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  return emailRegex.hasMatch(email);
}

bool isValidPhone(String phone) {
  final phoneRegex = RegExp(r'^\d{10,11}$');
  return phoneRegex.hasMatch(phone.replaceAll(RegExp(r'[^\d]'), ''));
}

bool isValidCPF(String cpf) {
  final cpfRegex = RegExp(r'^\d{3}\.\d{3}\.\d{3}-\d{2}$');
  return cpfRegex.hasMatch(cpf);
}
