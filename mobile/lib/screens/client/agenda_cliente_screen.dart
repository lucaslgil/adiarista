import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/agendamento_diarista.dart';
import '../../models/bloqueio_recorrente.dart';
import '../../models/configuracao_agenda.dart';
import '../../models/diarista_disponibilidade.dart';
import '../../services/agenda_service.dart';
import '../../services/agenda_validation_service.dart';
import '../../services/auth_service.dart';

class AgendaClienteScreen extends StatefulWidget {
  final String diaristaId;
  final String diaristaNome;

  const AgendaClienteScreen({
    Key? key,
    required this.diaristaId,
    required this.diaristaNome,
  }) : super(key: key);

  @override
  State<AgendaClienteScreen> createState() => _AgendaClienteScreenState();
}

class _AgendaClienteScreenState extends State<AgendaClienteScreen> {
  final _agendaService = AgendaService();
  bool _isLoading = false;
  bool _solicitando = false;

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
    await Future.wait([
      _carregarMes(),
      _carregarConfigRecorrentes(),
    ]);
  }

  Future<void> _carregarConfigRecorrentes() async {
    try {
      final config =
          await _agendaService.getConfiguracaoAgenda(widget.diaristaId);
      final bloqueios = await _agendaService.getBloqueiosRecorrentes(
          diaristaId: widget.diaristaId);
      if (mounted) {
        setState(() {
          _configuracaoAgenda = config;
          _bloqueiosRecorrentes = bloqueios;
        });
      }
    } catch (_) {}
  }

  String _chave(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _carregarMes() async {
    setState(() => _isLoading = true);
    try {
      final inicio = DateTime(_mesSelecionado.year, _mesSelecionado.month, 1);
      final fim = DateTime(_mesSelecionado.year, _mesSelecionado.month + 1, 0);

      final disp = await _agendaService.getDisponibilidade(
        diaristaId: widget.diaristaId,
        inicio: inicio,
        fim: fim,
      );
      final ags = await _agendaService.getAgendamentos(
        diaristaId: widget.diaristaId,
        inicio: inicio,
        fim: fim,
      );

      final dispMap = <String, DiaristaDisponibilidade>{};
      for (final d in disp) {
        dispMap[_chave(d.data)] = d;
      }
      final agMap = <String, List<AgendamentoDiarista>>{};
      for (final a in ags) {
        final k = _chave(a.dataAgendamento);
        agMap[k] ??= [];
        agMap[k]!.add(a);
      }

      if (mounted) {
        setState(() {
          _disponibilidades = dispMap;
          _agendamentos = agMap;
        });
      }
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

  /// Retorna o status efetivo do dia para a diarista (mesma lógica do worker).
  StatusDisponibilidade? _statusEfetivo(
      DateTime data, DiaristaDisponibilidade? dispManual) {
    if (dispManual != null) return dispManual.status;

    for (final regra in _bloqueiosRecorrentes) {
      if (regra.aplicaNaData(data)) return StatusDisponibilidade.bloqueado;
    }

    if (_configuracaoAgenda == null) return null;

    final diaSemana = data.weekday % 7;
    if (!_configuracaoAgenda!.diasTrabalho.contains(diaSemana)) {
      return StatusDisponibilidade.bloqueado;
    }

    return StatusDisponibilidade.integral;
  }

  void _abrirSolicitacao(DateTime data) {
    final chave = _chave(data);
    final disp = _disponibilidades[chave];
    final statusEfetivo = _statusEfetivo(data, disp);

    if (statusEfetivo == null ||
        statusEfetivo == StatusDisponibilidade.bloqueado) return;

    final ags = _agendamentos[chave] ?? [];
    final tiposDisponiveis = AgendaValidationService.recomendarTipos(
      agendamentosExistentes: ags,
      data: data,
    );

    if (tiposDisponiveis.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SolicitacaoSheet(
        data: data,
        disponibilidade: disp,
        tiposDisponiveis: tiposDisponiveis,
        diaristaNome: widget.diaristaNome,
        onSolicitar: (tipo, obs) async {
          setState(() => _solicitando = true);
          try {
            final userId = context.read<AuthService>().currentUserId;
            if (userId == null) return;
            await _agendaService.criarSolicitacaoAgendamento(
              diaristaId: widget.diaristaId,
              clienteId: userId,
              data: data,
              tipoServico: tipo,
              endereco: '',
              observacoes: obs,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      const Text('Solicitação enviada! Aguarde a confirmação.'),
                  backgroundColor: AppTheme.successColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              await _carregarMes();
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erro: $e'),
                  backgroundColor: AppTheme.errorColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } finally {
            if (mounted) setState(() => _solicitando = false);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.colorBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.colorBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.diaristaNome,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const Text(
              'Escolha um dia disponível',
              style: TextStyle(fontSize: 12, color: AppTheme.colorSubtext),
            ),
          ],
        ),
        actions: [
          if (_isLoading || _solicitando)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Legenda read-only ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                _LegendaDot(
                    cor: AppTheme.colorSurface,
                    label: 'Indisponível',
                    borda: AppTheme.colorBorder),
                const SizedBox(width: 12),
                _LegendaDot(
                    cor: AppTheme.warningColor.withAlpha(40),
                    label: 'Meio Período livre',
                    borda: AppTheme.warningColor),
                const SizedBox(width: 12),
                _LegendaDot(
                    cor: AppTheme.successColor.withAlpha(30),
                    label: 'Integral livre',
                    borda: AppTheme.successColor),
              ],
            ),
          ),

          // ── Navegação de Mês ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _navegarMes(1),
                ),
              ],
            ),
          ),

          // ── Labels dias da semana ────────────────────────────────────────
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

          // ── Calendário (read-only com tap) ───────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ClientCalendarGrid(
              mes: _mesSelecionado,
              disponibilidades: _disponibilidades,
              agendamentos: _agendamentos,
              bloqueiosRecorrentes: _bloqueiosRecorrentes,
              configuracaoAgenda: _configuracaoAgenda,
              onDiaDisponivel: _abrirSolicitacao,
            ),
          ),

          const SizedBox(height: 16),

          // ── Info box ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withAlpha(12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline,
                      size: 18, color: AppTheme.accentBlue),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Toque num dia disponível para solicitar agendamento.',
                      style:
                          TextStyle(fontSize: 13, color: AppTheme.accentBlue),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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

// ─── Grade Calendário (visão do cliente) ──────────────────────────────────────

class _ClientCalendarGrid extends StatelessWidget {
  final DateTime mes;
  final Map<String, DiaristaDisponibilidade> disponibilidades;
  final Map<String, List<AgendamentoDiarista>> agendamentos;
  final List<BloqueioRecorrente> bloqueiosRecorrentes;
  final ConfiguracaoAgenda? configuracaoAgenda;
  final void Function(DateTime) onDiaDisponivel;

  const _ClientCalendarGrid({
    required this.mes,
    required this.disponibilidades,
    required this.agendamentos,
    required this.bloqueiosRecorrentes,
    required this.configuracaoAgenda,
    required this.onDiaDisponivel,
  });

  String _chave(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Mesma hierarquia do worker: override manual > bloqueio recorrente > config de dias
  StatusDisponibilidade? _statusEfetivo(
      DateTime data, DiaristaDisponibilidade? dispManual) {
    if (dispManual != null) return dispManual.status;

    for (final regra in bloqueiosRecorrentes) {
      if (regra.aplicaNaData(data)) return StatusDisponibilidade.bloqueado;
    }

    if (configuracaoAgenda == null) return null;

    final diaSemana = data.weekday % 7;
    if (!configuracaoAgenda!.diasTrabalho.contains(diaSemana)) {
      return StatusDisponibilidade.bloqueado;
    }

    return StatusDisponibilidade.integral;
  }

  @override
  Widget build(BuildContext context) {
    final primeiroDiaMes = DateTime(mes.year, mes.month, 1);
    final diasNoMes = DateTime(mes.year, mes.month + 1, 0).day;
    final offsetInicio = primeiroDiaMes.weekday % 7;

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
      final isHoje = _chave(data) == _chave(DateTime.now());

      final statusEfetivo = _statusEfetivo(data, disp);

      // Calcula se ainda tem vaga
      final temVaga = statusEfetivo != null &&
          statusEfetivo != StatusDisponibilidade.bloqueado &&
          AgendaValidationService.recomendarTipos(
                  agendamentosExistentes: ags, data: data)
              .isNotEmpty;

      Color bg;
      Color borderColor;
      Color textColor = AppTheme.colorText;

      if (isPast || !temVaga) {
        bg = AppTheme.colorSurface;
        borderColor = AppTheme.colorBorder;
        textColor = AppTheme.colorSubtext.withAlpha(120);
      } else if (statusEfetivo == StatusDisponibilidade.meioPeriodo) {
        bg = AppTheme.warningColor.withAlpha(40);
        borderColor = AppTheme.warningColor;
        textColor = AppTheme.warningColor;
      } else {
        bg = AppTheme.successColor.withAlpha(30);
        borderColor = AppTheme.successColor;
        textColor = AppTheme.successColor;
      }

      cells.add(
        GestureDetector(
          onTap: (isPast || !temVaga) ? null : () => onDiaDisponivel(data),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isHoje ? AppTheme.accentBlue : borderColor,
                width: isHoje ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                '$dia',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isHoje ? FontWeight.w700 : FontWeight.w500,
                  color: isHoje ? AppTheme.accentBlue : textColor,
                ),
              ),
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

// ─── Bottom Sheet: Solicitar Agendamento ──────────────────────────────────────

class _SolicitacaoSheet extends StatefulWidget {
  final DateTime data;
  final DiaristaDisponibilidade? disponibilidade;
  final List<TipoServico> tiposDisponiveis;
  final String diaristaNome;
  final Future<void> Function(TipoServico tipo, String? obs) onSolicitar;

  const _SolicitacaoSheet({
    required this.data,
    required this.disponibilidade,
    required this.tiposDisponiveis,
    required this.diaristaNome,
    required this.onSolicitar,
  });

  @override
  State<_SolicitacaoSheet> createState() => _SolicitacaoSheetState();
}

class _SolicitacaoSheetState extends State<_SolicitacaoSheet> {
  late TipoServico _tipoSelecionado;
  final _obsController = TextEditingController();
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _tipoSelecionado = widget.tiposDisponiveis.first;
  }

  @override
  void dispose() {
    _obsController.dispose();
    super.dispose();
  }

  String _formatarData(DateTime d) {
    const dias = [
      'Segunda',
      'Terça',
      'Quarta',
      'Quinta',
      'Sexta',
      'Sábado',
      'Domingo'
    ];
    const meses = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez'
    ];
    return '${dias[d.weekday - 1]}, ${d.day} ${meses[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.colorBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
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

            const Text(
              'Solicitar Agendamento',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              '${_formatarData(widget.data)} • ${widget.diaristaNome}',
              style:
                  const TextStyle(fontSize: 13, color: AppTheme.colorSubtext),
            ),
            const SizedBox(height: 20),

            // Tipo de serviço
            const Text(
              'Tipo de Serviço',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.colorSubtext),
            ),
            const SizedBox(height: 10),

            ...widget.tiposDisponiveis.map((tipo) {
              final selecionado = _tipoSelecionado == tipo;
              final isMeio = tipo == TipoServico.meioPeriodo;
              return GestureDetector(
                onTap: () => setState(() => _tipoSelecionado = tipo),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: selecionado
                        ? AppTheme.primaryColor.withAlpha(8)
                        : AppTheme.colorSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selecionado
                          ? AppTheme.primaryColor
                          : AppTheme.colorBorder,
                      width: selecionado ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isMeio
                            ? Icons.wb_cloudy_outlined
                            : Icons.wb_sunny_outlined,
                        size: 22,
                        color: isMeio
                            ? AppTheme.warningColor
                            : AppTheme.successColor,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tipo.label,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                          Text(
                            isMeio
                                ? 'Manhã ou Tarde (08h–12h ou 13h–17h)'
                                : 'Dia completo (08h–17h)',
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.colorSubtext),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (selecionado)
                        const Icon(Icons.check_circle,
                            color: AppTheme.primaryColor, size: 20),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 8),

            // Observações (opcional)
            TextField(
              controller: _obsController,
              decoration: InputDecoration(
                hintText: 'Observações (opcional)...',
                hintStyle:
                    const TextStyle(color: AppTheme.colorSubtext, fontSize: 14),
                filled: true,
                fillColor: AppTheme.colorSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.colorBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.colorBorder),
                ),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _enviando
                    ? null
                    : () async {
                        setState(() => _enviando = true);
                        await widget.onSolicitar(
                          _tipoSelecionado,
                          _obsController.text.trim().isEmpty
                              ? null
                              : _obsController.text.trim(),
                        );
                        if (mounted) Navigator.pop(context);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _enviando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Solicitar Agendamento',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Legenda (cliente view) ───────────────────────────────────────────────────

class _LegendaDot extends StatelessWidget {
  final Color cor;
  final String label;
  final Color? borda;

  const _LegendaDot({required this.cor, required this.label, this.borda});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: cor,
            shape: BoxShape.circle,
            border:
                borda != null ? Border.all(color: borda!, width: 1.5) : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 10, color: AppTheme.colorSubtext)),
      ],
    );
  }
}
