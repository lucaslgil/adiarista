import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/agendamento_diarista.dart';
import '../../models/bloqueio_recorrente.dart';
import '../../models/configuracao_agenda.dart';
import '../../models/diarista_disponibilidade.dart';
import '../../services/agenda_service.dart';
import '../../services/auth_service.dart';

class AgendaWorkerScreen extends StatefulWidget {
  const AgendaWorkerScreen({Key? key}) : super(key: key);

  @override
  State<AgendaWorkerScreen> createState() => _AgendaWorkerScreenState();
}

class _AgendaWorkerScreenState extends State<AgendaWorkerScreen> {
  final _agendaService = AgendaService();
  bool _isLoading = false;

  DateTime _mesSelecionado = DateTime.now();
  Map<String, DiaristaDisponibilidade> _disponibilidades = {};
  Map<String, List<AgendamentoDiarista>> _agendamentos = {};
  List<BloqueioRecorrente> _bloqueiosRecorrentes = [];
  ConfiguracaoAgenda? _configuracaoAgenda;

  @override
  void initState() {
    super.initState();
    _carregarTudo();
  }

  Future<void> _carregarTudo() async {
    final userId = context.read<AuthService>().currentUserId;
    if (userId == null) return;
    await Future.wait([
      _carregarMes(),
      _carregarRecorrentes(userId),
      _carregarConfiguracao(userId),
    ]);
  }

  Future<void> _carregarConfiguracao(String userId) async {
    final config = await _agendaService.getConfiguracaoAgenda(userId);
    if (mounted) setState(() => _configuracaoAgenda = config);
  }

  Future<void> _carregarRecorrentes(String userId) async {
    final lista = await _agendaService.getBloqueiosRecorrentes(diaristaId: userId);
    if (mounted) setState(() => _bloqueiosRecorrentes = lista);
  }

  String _chave(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _carregarMes() async {
    final userId = context.read<AuthService>().currentUserId;
    if (userId == null) return;
    setState(() => _isLoading = true);
    try {
      final inicio = DateTime(_mesSelecionado.year, _mesSelecionado.month, 1);
      final fim = DateTime(_mesSelecionado.year, _mesSelecionado.month + 1, 0);

      print('🔄 [DEBUG] Carregando disponibilidades de ${_chave(inicio)} até ${_chave(fim)}');

      final disp = await _agendaService.getDisponibilidade(
        diaristaId: userId,
        inicio: inicio,
        fim: fim,
      );
      final ags = await _agendaService.getAgendamentos(
        diaristaId: userId,
        inicio: inicio,
        fim: fim,
      );

      print('📦 [DEBUG] ${disp.length} disponibilidades carregadas:');
      final dispMap = <String, DiaristaDisponibilidade>{};
      for (final d in disp) {
        final chaveData = _chave(d.data);
        print('  📅 ${chaveData} -> ${d.status.name}');
        dispMap[chaveData] = d;
      }

      final agMap = <String, List<AgendamentoDiarista>>{};
      for (final a in ags) {
        final k = _chave(a.dataAgendamento);
        agMap[k] ??= [];
        agMap[k]!.add(a);
      }

      print('✔️ [DEBUG] Mapa de disponibilidades preparado com ${dispMap.length} chaves');

      if (mounted) {
        setState(() {
          _disponibilidades = dispMap;
          _agendamentos = agMap;
        });
        print('🎨 [DEBUG] setState acionado, calendário deve atualizar agora');
      }
    } catch (e) {
      print('❌ [ERROR] Erro ao carregar mês: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navegarMes(int delta) {
    setState(() {
      _mesSelecionado =
          DateTime(_mesSelecionado.year, _mesSelecionado.month + delta, 1);
    });
    _carregarMes();
  }

  Future<void> _abrirOpcoesDia(DateTime data) async {
    final userId = context.read<AuthService>().currentUserId;
    if (userId == null) return;

    final chave = _chave(data);
    final disp = _disponibilidades[chave];
    final ags = _agendamentos[chave] ?? [];

    final recorrentesAtivos = _bloqueiosRecorrentes
        .where((r) => r.aplicaNaData(data))
        .toList();

    final acao = await showModalBottomSheet<_AcaoDia>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DayOptionsSheet(
        data: data,
        disponibilidade: disp,
        agendamentos: ags,
        bloqueiosRecorrentes: recorrentesAtivos,
      ),
    );

    if (acao == null) return;

    try {
      switch (acao) {
        case _AcaoDia.bloquearDia:
          await _agendaService.salvarDisponibilidade(
            diaristaId: userId,
            data: data,
            status: StatusDisponibilidade.bloqueado,
          );
        case _AcaoDia.bloquearSemanal:
          // Se já existe regra semanal ativa, remove (toggle)
          if (recorrentesAtivos.isNotEmpty) {
            for (final r in recorrentesAtivos) {
              await _agendaService.removerBloqueioRecorrente(id: r.id);
            }
          } else {
            await _agendaService.salvarBloqueioRecorrente(
              diaristaId: userId,
              tipo: TipoRecorrencia.semanal,
              valor: data.weekday % 7, // 0=Dom...6=Sab
              dataInicio: DateTime(data.year, data.month, data.day),
            );
            // Bloqueia também este dia específico
            await _agendaService.salvarDisponibilidade(
              diaristaId: userId,
              data: data,
              status: StatusDisponibilidade.bloqueado,
            );
          }
          await _carregarRecorrentes(userId);
        case _AcaoDia.liberarDia:
          // Remove bloqueio manual (se existir)
          await _agendaService.removerDisponibilidade(
            diaristaId: userId,
            data: data,
          );
          // Se o dia não está nos dias de trabalho, salva override explícito
          final diaSemana = data.weekday % 7;
          final naoDiaTrab = _configuracaoAgenda != null &&
              !_configuracaoAgenda!.diasTrabalho.contains(diaSemana);
          if (naoDiaTrab) {
            await _agendaService.salvarDisponibilidade(
              diaristaId: userId,
              data: data,
              status: StatusDisponibilidade.integral,
            );
          }
      }

      await Future.delayed(const Duration(milliseconds: 200));
      await _carregarMes();

      if (mounted) {
        final msgs = {
          _AcaoDia.bloquearDia: 'Dia bloqueado!',
          _AcaoDia.bloquearSemanal: recorrentesAtivos.isNotEmpty
              ? 'Bloqueio recorrente removido!'
              : 'Bloqueio semanal ativado!',
          _AcaoDia.liberarDia: 'Dia liberado!',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msgs[acao]!, style: const TextStyle(color: Colors.white)),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e', style: const TextStyle(color: Colors.white)),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.colorBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Text(
                    'Minha Agenda',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  if (_isLoading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),

            // ── Legenda ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _LegendaDot(cor: AppTheme.successColor, label: 'Disponível'),
                  const SizedBox(width: 12),
                  _LegendaDot(cor: const Color(0xFFE53935), label: 'Bloqueado'),
                  const SizedBox(width: 12),
                  _LegendaDot(cor: AppTheme.accentBlue, label: 'Agendamento'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Navegação de Mês ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _navegarMes(-1),
                  ),
                  Text(
                    _nomeMes(_mesSelecionado),
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _navegarMes(1),
                  ),
                ],
              ),
            ),

            // ── Labels dias da semana ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ['D', 'S', 'T', 'Q', 'Q', 'S', 'S']
                    .map((l) => Expanded(
                          child: Center(
                            child: Text(
                              l,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.colorSubtext,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),

            const SizedBox(height: 8),

            // ── Grade do Calendário ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _CalendarGrid(
                mes: _mesSelecionado,
                disponibilidades: _disponibilidades,
                agendamentos: _agendamentos,
                bloqueiosRecorrentes: _bloqueiosRecorrentes,
                configuracaoAgenda: _configuracaoAgenda,
                onDiaTocado: _abrirOpcoesDia,
              ),
            ),

            const SizedBox(height: 20),

            // ── Próximos Agendamentos ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: const [
                  Text(
                    'Próximos Agendamentos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _ProximosAgendamentos(agendamentos: _agendamentos),
            ),
          ],
        ),
      ),
    );
  }

  String _nomeMes(DateTime d) {
    const meses = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    return '${meses[d.month - 1]} ${d.year}';
  }
}

// ─── Ações do dia ────────────────────────────────────────────────────────────

enum _AcaoDia { bloquearDia, bloquearSemanal, liberarDia }

// ─── Grade Calendário ─────────────────────────────────────────────────────────

class _CalendarGrid extends StatelessWidget {
  final DateTime mes;
  final Map<String, DiaristaDisponibilidade> disponibilidades;
  final Map<String, List<AgendamentoDiarista>> agendamentos;
  final List<BloqueioRecorrente> bloqueiosRecorrentes;
  final ConfiguracaoAgenda? configuracaoAgenda;
  final void Function(DateTime) onDiaTocado;

  const _CalendarGrid({
    required this.mes,
    required this.disponibilidades,
    required this.agendamentos,
    required this.bloqueiosRecorrentes,
    required this.configuracaoAgenda,
    required this.onDiaTocado,
  });

  String _chave(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Retorna o status efetivo do dia considerando a hierarquia:
  /// 1. Override manual (disponibilidade específica para essa data)
  /// 2. Bloqueio recorrente semanal ativo
  /// 3. Dias de trabalho configurados
  /// 4. null = sem configuração (jornada não definida)
  StatusDisponibilidade? _statusEfetivo(
      DateTime data, DiaristaDisponibilidade? dispManual) {
    // 1. Override manual tem prioridade absoluta
    if (dispManual != null) return dispManual.status;

    // 2. Sem configuração de jornada → inconclusivo
    if (configuracaoAgenda == null) return null;

    // 3. Bloqueio recorrente ativo
    for (final regra in bloqueiosRecorrentes) {
      if (regra.aplicaNaData(data)) return StatusDisponibilidade.bloqueado;
    }

    // 4. Dia fora dos dias de trabalho
    final diaSemana = data.weekday % 7; // Dart weekday: 1=Seg...7=Dom → 0=Dom...6=Sab
    if (!configuracaoAgenda!.diasTrabalho.contains(diaSemana)) {
      return StatusDisponibilidade.bloqueado;
    }

    // 5. Disponível!
    return StatusDisponibilidade.integral;
  }

  @override
  Widget build(BuildContext context) {
    final primeiroDiaMes = DateTime(mes.year, mes.month, 1);
    final diasNoMes = DateTime(mes.year, mes.month + 1, 0).day;
    final offsetInicio = primeiroDiaMes.weekday % 7; // 0=Dom

    final cells = <Widget>[];

    for (int i = 0; i < offsetInicio; i++) {
      cells.add(const SizedBox());
    }

    for (int dia = 1; dia <= diasNoMes; dia++) {
      final data = DateTime(mes.year, mes.month, dia);
      final chave = _chave(data);
      final disp = disponibilidades[chave];
      final ags = agendamentos[chave] ?? [];
      final isPast =
          data.isBefore(DateTime.now().subtract(const Duration(days: 1)));
      final isHoje = chave == _chave(DateTime.now());
      final temAgendamento = ags.any((a) =>
          a.status != StatusAgendamento.cancelado &&
          a.status != StatusAgendamento.finalizado);

      final statusEfetivo = _statusEfetivo(data, disp);
      final isRecorrente = disp == null &&
          bloqueiosRecorrentes.any((r) => r.aplicaNaData(data));

      Color bg;
      Color textColor;

      if (temAgendamento && !isPast) {
        // Agendado → azul
        bg = AppTheme.accentBlue.withAlpha(22);
        textColor = AppTheme.accentBlue;
      } else if (statusEfetivo == null) {
        // Sem configuração → cinza neutro
        bg = isPast
            ? AppTheme.colorBorder.withAlpha(40)
            : AppTheme.colorSurface;
        textColor = isPast
            ? AppTheme.colorSubtext.withAlpha(80)
            : AppTheme.colorSubtext;
      } else if (statusEfetivo == StatusDisponibilidade.bloqueado) {
        // Bloqueado → vermelho
        bg = isPast
            ? const Color(0xFFFFCDD2).withAlpha(50)
            : const Color(0xFFFFEBEE);
        textColor = isPast
            ? Colors.red.withAlpha(80)
            : const Color(0xFFE53935);
      } else {
        // Disponível → verde
        bg = isPast
            ? AppTheme.successColor.withAlpha(15)
            : AppTheme.successColor.withAlpha(28);
        textColor = isPast
            ? AppTheme.successColor.withAlpha(100)
            : AppTheme.successColor;
      }

      cells.add(
        GestureDetector(
          onTap: isPast ? null : () => onDiaTocado(data),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: isHoje
                  ? Border.all(color: AppTheme.accentBlue, width: 2)
                  : statusEfetivo == StatusDisponibilidade.bloqueado && !isPast
                      ? Border.all(
                          color: const Color(0xFFEF9A9A), width: 1)
                      : null,
            ),
            child: Stack(
              children: [
                // Ícone pequeno: recorrente ou agendado
                if (!isPast && isRecorrente)
                  const Positioned(
                    top: 2,
                    right: 3,
                    child: Icon(Icons.repeat, size: 9,
                        color: Color(0xFFE53935)),
                  ),
                if (!isPast && temAgendamento)
                  Positioned(
                    top: 2,
                    right: isRecorrente ? 14 : 3,
                    child: Icon(Icons.circle, size: 6,
                        color: AppTheme.accentBlue.withAlpha(200)),
                  ),
                Center(
                  child: Text(
                    '$dia',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isHoje ? FontWeight.w700 : FontWeight.w500,
                      color: isHoje ? AppTheme.accentBlue : textColor,
                      decoration: statusEfetivo == StatusDisponibilidade.bloqueado && !temAgendamento
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: const Color(0xFFEF9A9A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1,
      children: cells,
    );
  }
}

// ─── Próximos Agendamentos ────────────────────────────────────────────────────

class _ProximosAgendamentos extends StatelessWidget {
  final Map<String, List<AgendamentoDiarista>> agendamentos;

  const _ProximosAgendamentos({required this.agendamentos});

  @override
  Widget build(BuildContext context) {
    final hoje = DateTime.now();
    final lista = agendamentos.entries
        .where((e) {
          final partes = e.key.split('-');
          final d = DateTime(
            int.parse(partes[0]),
            int.parse(partes[1]),
            int.parse(partes[2]),
          );
          return !d.isBefore(DateTime(hoje.year, hoje.month, hoje.day));
        })
        .expand((e) => e.value)
        .where((a) =>
            a.status == StatusAgendamento.confirmado ||
            a.status == StatusAgendamento.pendente)
        .toList()
      ..sort((a, b) => a.dataAgendamento.compareTo(b.dataAgendamento));

    if (lista.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 44, color: AppTheme.colorSubtext),
            SizedBox(height: 10),
            Text(
              'Nenhum agendamento próximo',
              style: TextStyle(color: AppTheme.colorSubtext, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemCount: lista.length,
      itemBuilder: (_, i) => _AgendamentoTile(agendamento: lista[i]),
    );
  }
}

class _AgendamentoTile extends StatelessWidget {
  final AgendamentoDiarista agendamento;

  const _AgendamentoTile({required this.agendamento});

  @override
  Widget build(BuildContext context) {
    final isPendente = agendamento.status == StatusAgendamento.pendente;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.colorSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.colorBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: agendamento.tipoServico == TipoServico.integral
                  ? AppTheme.successColor.withAlpha(20)
                  : AppTheme.warningColor.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              agendamento.tipoServico == TipoServico.integral
                  ? Icons.wb_sunny_outlined
                  : Icons.wb_cloudy_outlined,
              color: agendamento.tipoServico == TipoServico.integral
                  ? AppTheme.successColor
                  : AppTheme.warningColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agendamento.dataFormatada,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  '${agendamento.tipoServico.label} • ${agendamento.horarioFormatado}',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.colorSubtext),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: agendamento.status.cor.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isPendente ? 'Pendente' : 'Confirmado',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: agendamento.status.cor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom Sheet: Opções do Dia ──────────────────────────────────────────────

class _DayOptionsSheet extends StatelessWidget {
  final DateTime data;
  final DiaristaDisponibilidade? disponibilidade;
  final List<AgendamentoDiarista> agendamentos;
  final List<BloqueioRecorrente> bloqueiosRecorrentes;

  const _DayOptionsSheet({
    required this.data,
    required this.disponibilidade,
    required this.agendamentos,
    required this.bloqueiosRecorrentes,
  });

  String _formatarData(DateTime d) {
    const dias = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
    const meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    return '${dias[d.weekday - 1]}, ${d.day} de ${meses[d.month - 1]}';
  }

  String _nomeDiaSemana(int weekday) {
    const nomes = ['Domingo', 'Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 'Sexta-feira', 'Sábado'];
    return nomes[(weekday - 1).clamp(0, 6)];
  }

  @override
  Widget build(BuildContext context) {
    final temRecorrente = bloqueiosRecorrentes.isNotEmpty;
    final diaNome = _nomeDiaSemana(data.weekday);
    final bloqueioBtn = temRecorrente
        ? 'Remover bloqueio de toda $diaNome'
        : 'Bloquear toda $diaNome';

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.colorBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.colorBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Cabeçalho
          Text(
            _formatarData(data),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            agendamentos.isEmpty
                ? 'Nenhum agendamento'
                : '${agendamentos.length} agendamento(s)',
            style: const TextStyle(fontSize: 12, color: AppTheme.colorSubtext),
          ),

          // Agendamentos existentes
          if (agendamentos.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...agendamentos.map(
              (a) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue.withAlpha(14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, size: 14, color: AppTheme.accentBlue),
                    const SizedBox(width: 8),
                    Text(
                      '${a.tipoServico.label} • ${a.horarioFormatado}',
                      style: const TextStyle(fontSize: 13, color: AppTheme.accentBlue),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Ação 1: Bloquear este dia
          _AcaoTile(
            icone: Icons.block_outlined,
            cor: const Color(0xFFE53935),
            titulo: 'Bloquear este dia',
            subtitulo: 'Indisponível apenas em ${data.day}/${data.month}',
            onTap: () => Navigator.pop(context, _AcaoDia.bloquearDia),
          ),
          const SizedBox(height: 8),

          // Ação 2: Bloquear / remover toda semana
          _AcaoTile(
            icone: temRecorrente ? Icons.repeat_on : Icons.repeat,
            cor: temRecorrente ? Colors.orange : Colors.deepPurple,
            titulo: bloqueioBtn,
            subtitulo: temRecorrente
                ? 'Remove o bloqueio semanal de $diaNome'
                : 'Bloqueia todo(a) $diaNome automaticamente',
            onTap: () => Navigator.pop(context, _AcaoDia.bloquearSemanal),
          ),
          const SizedBox(height: 8),

          // Ação 3: Liberar este dia
          _AcaoTile(
            icone: Icons.check_circle_outline,
            cor: AppTheme.successColor,
            titulo: 'Liberar este dia',
            subtitulo: 'Marcar como disponível em ${data.day}/${data.month}',
            onTap: () => Navigator.pop(context, _AcaoDia.liberarDia),
          ),
        ],
      ),
    );
  }
}

// ─── Tile de Ação ─────────────────────────────────────────────────────────────

class _AcaoTile extends StatelessWidget {
  final IconData icone;
  final Color cor;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  const _AcaoTile({
    required this.icone,
    required this.cor,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cor.withAlpha(14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cor.withAlpha(60), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cor.withAlpha(22),
                  shape: BoxShape.circle,
                ),
                child: Icon(icone, color: cor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: cor)),
                    const SizedBox(height: 2),
                    Text(subtitulo,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.colorSubtext)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cor.withAlpha(140), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Legenda ──────────────────────────────────────────────────────────────────

class _LegendaDot extends StatelessWidget {
  final Color cor;
  final String label;

  const _LegendaDot({required this.cor, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: cor, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppTheme.colorSubtext)),
      ],
    );
  }
}
