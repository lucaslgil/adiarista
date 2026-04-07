/// Constantes do aplicativo
class AppConstants {
  // URLs
  static const String supportEmail = 'contato@adiarista.com.br';
  static const String websiteUrl = 'https://adiarista.com.br';
  static const String privacyPolicyUrl = '$websiteUrl/privacy';
  static const String termsOfServiceUrl = '$websiteUrl/terms';

  // Timings
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration shortDelay = Duration(milliseconds: 500);
  static const Duration mediumDelay = Duration(seconds: 1);
  static const Duration longDelay = Duration(seconds: 2);

  // Validação
  static const int minPasswordLength = 6;
  static const int minNameLength = 3;
  static const int maxNameLength = 255;

  // Regex patterns
  static const String emailPattern =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phonePattern = r'^\d{10,11}$';
  static const String cpfPattern = r'^\d{3}\.\d{3}\.\d{3}-\d{2}$';

  // Mensagens padrão
  static const String errorGeneral =
      'Ocorreu um erro. Por favor, tente novamente.';
  static const String errorNetwork = 'Erro de conexão. Verifique sua internet.';
  static const String errorNotFound = 'Dados não encontrados.';
  static const String successGeneral = 'Operação realizada com sucesso!';

  // Limites
  static const int maxSolicitacoesPerPage = 10;
  static const int maxDiaristasFiltradas = 50;
  static const double maxDistance = 50.0; // km
  static const double minAvaliacao = 0.0;
  static const double maxAvaliacao = 5.0;

  // Status codes
  static const int httpOk = 200;
  static const int httpCreated = 201;
  static const int httpBadRequest = 400;
  static const int httpUnauthorized = 401;
  static const int httpForbidden = 403;
  static const int httpNotFound = 404;
  static const int httpServerError = 500;

  // Tipos de usuário
  static const String userTypeCliente = 'cliente';
  static const String userTypeDiarista = 'diarista';

  // Status de solicitação
  static const String statusPendente = 'pendente';
  static const String statusAceita = 'aceita';
  static const String statusEmAndamento = 'em_andamento';
  static const String statusFinalizada = 'finalizada';
  static const String statusCancelada = 'cancelada';

  // Tipos de limpeza
  static const List<String> tiposLimpeza = [
    'Limpeza Geral',
    'Limpeza Profunda',
    'Organização',
    'Enceramento de Piso',
    'Limpeza de Cozinha',
    'Limpeza de Banheiro',
    'Limpeza Pós-Obra',
    'Limpeza Comercial',
  ];

  // Especialidades
  static const List<String> especialidades = [
    'Limpeza Residencial',
    'Limpeza Comercial',
    'Organização',
    'Enceramento',
    'Dedetização',
    'Higienização',
  ];

  // Regiões exemplo
  static const List<String> regioes = [
    'Centro',
    'Zona Norte',
    'Zona Sul',
    'Zona Leste',
    'Zona Oeste',
  ];
}

/// Constantes de API
class ApiConstants {
  static const String baseUrl = 'https://seu-projeto.supabase.co';
  static const String apiVersion = 'v1';
  static const Duration timeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 15);

  // Endpoints
  static const String usersEndpoint = '/rest/$apiVersion/users';
  static const String diaristaEndpoint = '/rest/$apiVersion/diaristas';
  static const String solicitacoesEndpoint = '/rest/$apiVersion/solicitacoes';
  static const String avaliacoesEndpoint = '/rest/$apiVersion/avaliacoes';
}

/// Constantes de armazenamento local
class StorageConstants {
  static const String userIdKey = 'user_id';
  static const String userTypeKey = 'user_type';
  static const String userNameKey = 'user_name';
  static const String userEmailKey = 'user_email';
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String lastSyncKey = 'last_sync';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';
}
