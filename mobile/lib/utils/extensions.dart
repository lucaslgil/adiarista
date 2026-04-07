/// Extensões utilitárias para tipos padrão do Dart

/// Extensão para String
extension StringExtension on String {
  /// Capitalizar primeira letra
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  /// Verificar se é email válido
  bool isValidEmail() {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }

  /// Remover espaços extras
  String removeExtraSpaces() {
    return replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Truncar texto
  String truncate(int length, {String ellipsis = '...'}) {
    if (this.length <= length) return this;
    return substring(0, length - ellipsis.length) + ellipsis;
  }

  /// Obter iniciais
  String getInitials({int max = 2}) {
    return split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase())
        .take(max)
        .join();
  }
}

/// Extensão para DateTime
extension DateTimeExtension on DateTime {
  /// Formatar como data legível
  String toFormattedDate({String locale = 'pt_BR'}) {
    final months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return '$day de ${months[month - 1]} de $year';
  }

  /// Formatar como hora legível
  String toFormattedTime() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// Formatar como data e hora
  String toFormattedDateTime() {
    return '${toFormattedDate()} às ${toFormattedTime()}';
  }

  /// Verificar se é hoje
  bool isToday() {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Verificar se é ontem
  bool isYesterday() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Tempo relativo (ex: "há 2 horas")
  String toRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 60) {
      return 'agora';
    } else if (difference.inMinutes < 60) {
      return 'há ${difference.inMinutes} minuto(s)';
    } else if (difference.inHours < 24) {
      return 'há ${difference.inHours} hora(s)';
    } else if (difference.inDays < 7) {
      return 'há ${difference.inDays} dia(s)';
    } else {
      return toFormattedDate();
    }
  }
}

/// Extensão para double
extension DoubleExtension on double {
  /// Arredondar para N casas decimais
  double roundTo(int places) {
    final factor = 10.0 * places;
    return (this * factor).round() / factor;
  }

  /// Formatar como moeda
  String toCurrencyString() {
    return 'R\$ ${toStringAsFixed(2).replaceAll('.', ',')}';
  }

  /// Formatar com separadores
  String toFormattedString({int decimals = 2}) {
    return toStringAsFixed(decimals);
  }
}

/// Extensão para List
extension ListExtension<T> on List<T> {
  /// Obter páginas
  List<List<T>> paginate(int pageSize) {
    final List<List<T>> pages = [];
    for (int i = 0; i < length; i += pageSize) {
      pages.add(sublist(i, (i + pageSize > length) ? length : i + pageSize));
    }
    return pages;
  }

  /// Remover duplicatas mantendo ordem
  List<T> unique() {
    final Set<T> seen = {};
    final List<T> result = [];
    for (final item in this) {
      if (!seen.contains(item)) {
        seen.add(item);
        result.add(item);
      }
    }
    return result;
  }

  /// Shuffled mantendo índices específicos
  List<T> shuffleExcept(List<int> indices) {
    final Map<int, T> fixed = {};
    for (final index in indices) {
      if (index < length) {
        fixed[index] = this[index];
      }
    }
    final List<T> result = List.from(this)..shuffle();
    fixed.forEach((index, value) {
      result[index] = value;
    });
    return result;
  }
}

/// Extensão para gerenciamento de estado
extension StateExtension<T> on Iterable<T> {
  /// Agrupar por propriedade
  Map<K, List<T>> groupBy<K>(K Function(T) selector) {
    final Map<K, List<T>> groups = {};
    for (final item in this) {
      final key = selector(item);
      groups.putIfAbsent(key, () => []).add(item);
    }
    return groups;
  }

  /// Transformar com índice
  List<U> mapIndexed<U>(U Function(T, int) transform) {
    return toList().asMap().entries.map((e) => transform(e.value, e.key)).toList();
  }
}

/// Extensão para validações
extension ValidationExtension on String {
  /// Melhorar para validações estruturadas
  bool matches(Pattern pattern) {
    return RegExp(pattern as String).hasMatch(this);
  }

  /// Normalizar para busca
  String toSearchNormal() {
    return toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ã', 'a')
        .replaceAll('õ', 'o')
        .replaceAll('ç', 'c')
        .trim();
  }
}
