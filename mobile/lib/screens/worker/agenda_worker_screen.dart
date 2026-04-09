import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/agendamento_diarista.dart';
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

  @override
  void initState() {
    super.initState();
    _carregarMes();
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

  Future<void> _abrirOpcoesDia(DateTime data) async {
    final userId = context.read<AuthService>().currentUserId;
    if (userId == null) return;

    final chave = _chave(data);
    final disp = _disponibilidades[chave];
    final ags = _agendamentos[chave] ?? [];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DayOptionsSheet(
        data: data,
        disponibilidade: disp,
        agendamentos: ags,
        onSalvar: (status) async {
          await _agendaService.salvarDisponibilidade(
            diaristaId: userId,
            data: data,
            status: status,
          );
          await _carregarMes();
        },
      ),
    );
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
                  _LegendaDot(
                      cor: AppTheme.colorSubtext.withAlpha(80),
                      label: 'Bloqueado'),
                  const SizedBox(width: 12),
                  _LegendaDot(
                      cor: AppTheme.warningColor, label: 'Meio Período'),
                  const SizedBox(width: 12),
                  _LegendaDot(cor: AppTheme.successColor, label: 'Integral'),
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

// ─── Grade Calendário ─────────────────────────────────────────────────────────

class _CalendarGrid extends StatelessWidget {
  final DateTime mes;
  final Map<String, DiaristaDisponibilidade> disponibilidades;
  final Map<String, List<AgendamentoDiarista>> agendamentos;
  final void Function(DateTime) onDiaTocado;

  const _CalendarGrid({
    required this.mes,
    required this.disponibilidades,
    required this.agendamentos,
    required this.onDiaTocado,
  });

  String _chave(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final primeiroDiaMes = DateTime(mes.year, mes.month, 1);
    final diasNoMes = DateTime(mes.year, mes.month + 1, 0).day;
    final offsetInicio = primeiroDiaMes.weekday % 7; // 0=Dom

    final cells = <Widget>[];

    // Células vazias antes do dia 1
    for (int i = 0; i < offsetInicio; i++) {
      cells.add(const SizedBox());
    }

    // Dias do mês
    for (int dia = 1; dia <= diasNoMes; dia++) {
      final data = DateTime(mes.year, mes.month, dia);
      final chave = _chave(data);
      final disp = disponibilidades[chave];
      final ags = agendamentos[chave] ?? [];
      final isPast =
          data.isBefore(DateTime.now().subtract(const Duration(days: 1)));
      final isHoje = _chave(data) == _chave(DateTime.now());

      Color bg;
      Color textColor;
      if (disp == null || disp.status == StatusDisponibilidade.bloqueado) {
        bg =
            isPast ? AppTheme.colorBorder.withAlpha(60) : AppTheme.colorSurface;
        textColor =
            isPast ? AppTheme.colorSubtext.withAlpha(100) : AppTheme.colorText;
      } else if (disp.status == StatusDisponibilidade.meioPeriodo) {
        bg = AppTheme.warningColor.withAlpha(30);
        textColor = AppTheme.warningColor;
      } else {
        bg = AppTheme.successColor.withAlpha(25);
        textColor = AppTheme.successColor;
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
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$dia',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isHoje ? FontWeight.w700 : FontWeight.w500,
                    color: isHoje ? AppTheme.accentBlue : textColor,
                  ),
                ),
                if (ags.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      ags.length.clamp(0, 2),
                      (_) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppTheme.accentBlue,
                          shape: BoxShape.circle,
                        ),
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

class _DayOptionsSheet extends StatefulWidget {
  final DateTime data;
  final DiaristaDisponibilidade? disponibilidade;
  final List<AgendamentoDiarista> agendamentos;
  final Future<void> Function(StatusDisponibilidade) onSalvar;

  const _DayOptionsSheet({
    required this.data,
    required this.disponibilidade,
    required this.agendamentos,
    required this.onSalvar,
  });

  @override
  State<_DayOptionsSheet> createState() => _DayOptionsSheetState();
}

class _DayOptionsSheetState extends State<_DayOptionsSheet> {
  late StatusDisponibilidade _statusSelecionado;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _statusSelecionado =
        widget.disponibilidade?.status ?? StatusDisponibilidade.bloqueado;
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
    return '${dias[d.weekday - 1]}, ${d.day} de ${meses[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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

          Text(
            _formatarData(widget.data),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),

          // Agendamentos existentes
          if (widget.agendamentos.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...widget.agendamentos.map(
              (a) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue.withAlpha(12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month,
                        size: 14, color: AppTheme.accentBlue),
                    const SizedBox(width: 8),
                    Text(
                      '${a.tipoServico.label} • ${a.horarioFormatado}',
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.accentBlue),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),
          const Text(
            'Disponibilidade',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.colorSubtext),
          ),
          const SizedBox(height: 10),

          // Opções de status
          _StatusOption(
            status: StatusDisponibilidade.bloqueado,
            selecionado: _statusSelecionado == StatusDisponibilidade.bloqueado,
            onTap: () => setState(
                () => _statusSelecionado = StatusDisponibilidade.bloqueado),
            descricao: 'Dia indisponível',
          ),
          const SizedBox(height: 8),
          _StatusOption(
            status: StatusDisponibilidade.meioPeriodo,
            selecionado:
                _statusSelecionado == StatusDisponibilidade.meioPeriodo,
            onTap: () => setState(
                () => _statusSelecionado = StatusDisponibilidade.meioPeriodo),
            descricao: 'Aceita até 2 clientes de 4h',
          ),
          const SizedBox(height: 8),
          _StatusOption(
            status: StatusDisponibilidade.integral,
            selecionado: _statusSelecionado == StatusDisponibilidade.integral,
            onTap: () => setState(
                () => _statusSelecionado = StatusDisponibilidade.integral),
            descricao: 'Disponível para 1 cliente de 8h',
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _salvando
                  ? null
                  : () async {
                      setState(() => _salvando = true);
                      await widget.onSalvar(_statusSelecionado);
                      if (mounted) Navigator.pop(context);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _salvando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Salvar',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  final StatusDisponibilidade status;
  final bool selecionado;
  final VoidCallback onTap;
  final String descricao;

  const _StatusOption({
    required this.status,
    required this.selecionado,
    required this.onTap,
    required this.descricao,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selecionado ? status.cor.withAlpha(20) : AppTheme.colorSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selecionado ? status.cor : AppTheme.colorBorder,
            width: selecionado ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: status.cor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: selecionado ? status.cor : AppTheme.colorText,
                  ),
                ),
                Text(
                  descricao,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.colorSubtext),
                ),
              ],
            ),
            const Spacer(),
            if (selecionado)
              Icon(Icons.check_circle, color: status.cor, size: 20),
          ],
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
