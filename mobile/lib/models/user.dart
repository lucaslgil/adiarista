/// Modelo de usuário do aplicativo
class User {
  final String id;
  final String nome;
  final String email;
  final String tipoUsuario; // 'cliente', 'diarista' ou 'admin'
  final String? fotoPerfil;
  final DateTime criadoEm;

  User({
    required this.id,
    required this.nome,
    required this.email,
    required this.tipoUsuario,
    this.fotoPerfil,
    required this.criadoEm,
  });

  bool get isAdmin => tipoUsuario == 'admin';
  bool get isCliente => tipoUsuario == 'cliente';
  bool get isDiarista => tipoUsuario == 'diarista';

  /// Criar User a partir de JSON (vindo do Supabase)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      nome: json['nome'] as String,
      email: json['email'] as String,
      tipoUsuario: json['tipo_usuario'] as String,
      fotoPerfil: json['foto_perfil'] as String?,
      criadoEm: DateTime.parse(json['criado_em'] as String),
    );
  }

  /// Converter User para JSON (para enviar ao Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'tipo_usuario': tipoUsuario,
      'foto_perfil': fotoPerfil,
      'criado_em': criadoEm.toIso8601String(),
    };
  }

  /// Criar cópia com alguns campos modificados
  User copyWith({
    String? id,
    String? nome,
    String? email,
    String? tipoUsuario,
    String? fotoPerfil,
    DateTime? criadoEm,
  }) {
    return User(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      tipoUsuario: tipoUsuario ?? this.tipoUsuario,
      fotoPerfil: fotoPerfil ?? this.fotoPerfil,
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }
}
