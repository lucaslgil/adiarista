import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/endereco_cliente.dart';
import '../../models/servico.dart';
import '../../models/solicitacao.dart';
import '../../services/auth_service.dart';
import '../../services/endereco_service.dart';
import '../../services/user_service.dart';
import 'meus_enderecos_screen.dart';

class HomeClientScreen extends StatefulWidget {
  const HomeClientScreen({Key? key}) : super(key: key);

  @override
  State<HomeClientScreen> createState() => _HomeClientScreenState();
}

class _HomeClientScreenState extends State<HomeClientScreen> {
  int _selectedIndex = 0;
  bool _isLoading = false;
  List<Solicitacao> _solicitacoes = [];
  String _nomeUsuario = 'Cliente';

  // Servicos rapidos oferecidos
  static const _servicos = [
    {'icon': Icons.home_outlined, 'label': 'Casa', 'tipo': 'casa'},
    {
      'icon': Icons.apartment_outlined,
      'label': 'Apartamento',
      'tipo': 'apartamento'
    },
    {
      'icon': Icons.business_outlined,
      'label': 'Comercial',
      'tipo': 'comercial'
    },
    {
      'icon': Icons.cleaning_services_outlined,
      'label': 'Faxina',
      'tipo': 'faxina'
    },
    {'icon': Icons.window_outlined, 'label': 'Vidros', 'tipo': 'vidros'},
    {
      'icon': Icons.local_laundry_service_outlined,
      'label': 'Lavanderia',
      'tipo': 'lavanderia'
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final authService = context.read<AuthService>();
      final userService = context.read<UserService>();
      final userId = authService.currentUserId;
      if (userId != null) {
        final solicitacoes = await userService.getSolicitacoesCliente(userId);
        final user = await userService.getUserById(userId);
        if (mounted) {
          setState(() {
            _solicitacoes = solicitacoes;
            _nomeUsuario = user?.nome.split(' ').first ?? 'Cliente';
          });
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    await context.read<AuthService>().logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.colorBackground,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _HomeTab(
            nomeUsuario: _nomeUsuario,
            servicos: _servicos,
            solicitacoesAtivas: _solicitacoes
                .where((s) =>
                    s.status == 'pendente' ||
                    s.status == 'aceita' ||
                    s.status == 'em_andamento')
                .toList(),
            isLoading: _isLoading,
            onRefresh: _loadData,
          ),
          _HistoricoTab(solicitacoes: _solicitacoes),
          const MeusEnderecosScreen(),
          _PerfilTab(nome: _nomeUsuario, onLogout: _handleLogout),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Atividade',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on),
            label: 'Endereços',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Conta',
          ),
        ],
      ),
    );
  }
}

// ─── Aba Home (estilo Uber) ───────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  final String nomeUsuario;
  final List<Map<String, Object>> servicos;
  final List<Solicitacao> solicitacoesAtivas;
  final bool isLoading;
  final VoidCallback onRefresh;

  const _HomeTab({
    required this.nomeUsuario,
    required this.servicos,
    required this.solicitacoesAtivas,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final hora = DateTime.now().hour;
    final saudacao = hora < 12
        ? 'Bom dia'
        : hora < 18
            ? 'Boa tarde'
            : 'Boa noite';

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: CustomScrollView(
        slivers: [
          // Header com saudacao
          SliverToBoxAdapter(
            child: Container(
              color: AppTheme.primaryColor,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 24,
                right: 24,
                bottom: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$saudacao,',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            nomeUsuario,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_outlined,
                              color: Colors.white, size: 22),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Barra de busca
                  GestureDetector(
                    onTap: () => context.push('/buscar-diaristas'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search,
                              color: AppTheme.colorSubtext, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            'Qual servico voce precisa?',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Servicos rapidos
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
              child: Text('Para voce',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 104,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemCount: servicos.length,
                itemBuilder: (context, i) {
                  final s = servicos[i];
                  return _ServicoRapidoItem(
                    icon: s['icon'] as IconData,
                    label: s['label'] as String,
                    onTap: () => _abrirFiltroRapido(
                      context,
                      tipoInicial: s['tipo'] as String,
                    ),
                  );
                },
              ),
            ),
          ),

          // Botoes de acao
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _abrirFiltroRapido(context),
                    icon: const Icon(Icons.tune),
                    label: const Text('Busca rapida por data'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/buscar-diaristas'),
                    icon: const Icon(Icons.people_outline),
                    label: const Text('Ver todas as profissionais'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      textStyle: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Solicitacoes ativas
          if (solicitacoesAtivas.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
                child: Text('Em andamento',
                    style: Theme.of(context).textTheme.titleLarge),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: _SolicitacaoCard(solicitacao: solicitacoesAtivas[i]),
                ),
                childCount: solicitacoesAtivas.length,
              ),
            ),
          ],

          // Dicas / banner promocional
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dicas rapidas',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  _DicaCard(
                    icon: Icons.star_outline,
                    titulo: 'Escolha pelas avaliacoes',
                    descricao:
                        'Diaristas com mais estrelas entregam melhores resultados',
                    cor: AppTheme.accentOrange,
                  ),
                  const SizedBox(height: 10),
                  _DicaCard(
                    icon: Icons.schedule_outlined,
                    titulo: 'Agende com antecedencia',
                    descricao:
                        'Garantia de disponibilidade agendando com 48h de antecedencia',
                    cor: AppTheme.accentBlue,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper: abre o filtro rápido (busca por data/serviço) ───────────────────

void _abrirFiltroRapido(BuildContext context, {String? tipoInicial}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FiltroRapidoSheet(tipoInicial: tipoInicial),
  );
}

// ─── Sheet de filtro rápido ───────────────────────────────────────────────────

class _FiltroRapidoSheet extends StatefulWidget {
  final String? tipoInicial;
  const _FiltroRapidoSheet({this.tipoInicial});

  @override
  State<_FiltroRapidoSheet> createState() => _FiltroRapidoSheetState();
}

class _FiltroRapidoSheetState extends State<_FiltroRapidoSheet> {
  DateTime? _dataSelecionada;
  EnderecoCliente? _enderecoSelecionado;
  List<EnderecoCliente> _enderecos = [];
  bool _loadingEnderecos = true;
  String? _tipoSelecionado;

  static const _tipos = [
    {'label': 'Qualquer', 'value': null},
    {'label': 'Casa', 'value': 'casa'},
    {'label': 'Apartamento', 'value': 'apartamento'},
    {'label': 'Faxina', 'value': 'faxina'},
    {'label': 'Comercial', 'value': 'comercial'},
  ];

  @override
  void initState() {
    super.initState();
    _tipoSelecionado = widget.tipoInicial;
    _carregarEnderecos();
  }

  Future<void> _carregarEnderecos() async {
    try {
      final authService = context.read<AuthService>();
      final enderecoService = context.read<EnderecoService>();
      final userId = authService.currentUserId;
      if (userId != null) {
        final lista = await enderecoService.getEnderecos(userId);
        if (mounted) {
          setState(() {
            _enderecos = lista;
            _enderecoSelecionado =
                lista.where((e) => e.principal).firstOrNull ??
                    lista.firstOrNull;
          });
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingEnderecos = false);
    }
  }

  Future<void> _selecionarData() async {
    final hoje = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada ?? hoje.add(const Duration(days: 1)),
      firstDate: hoje,
      lastDate: hoje.add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _dataSelecionada = picked);
  }

  void _buscar() {
    Navigator.pop(context);
    context.push('/buscar-diaristas', extra: {
      if (_tipoSelecionado != null) 'tipo': _tipoSelecionado,
      if (_dataSelecionada != null) 'data': _dataSelecionada!.toIso8601String(),
      if (_enderecoSelecionado != null) 'endereco': _enderecoSelecionado,
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmtData = _dataSelecionada != null
        ? DateFormat("EEE, d 'de' MMM", 'pt_BR').format(_dataSelecionada!)
        : null;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.colorBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Busca Rapida',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Escolha a data e veja quem esta disponivel',
                style: TextStyle(fontSize: 14, color: AppTheme.colorSubtext)),
            const SizedBox(height: 24),

            // Tipo de servico
            const Text('Tipo de servico',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.colorSubtext)),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _tipos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final t = _tipos[i];
                  final selected = _tipoSelecionado == t['value'];
                  return GestureDetector(
                    onTap: () => setState(
                        () => _tipoSelecionado = t['value'] as String?),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.primaryColor
                            : AppTheme.colorSurface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: selected
                                ? AppTheme.primaryColor
                                : AppTheme.colorBorder),
                      ),
                      child: Center(
                        child: Text(
                          t['label'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: selected ? Colors.white : AppTheme.colorText,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Data
            const Text('Quando?',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.colorSubtext)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _selecionarData,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _dataSelecionada != null
                      ? AppTheme.accentBlue.withAlpha(12)
                      : AppTheme.colorSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _dataSelecionada != null
                        ? AppTheme.accentBlue
                        : AppTheme.colorBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        color: _dataSelecionada != null
                            ? AppTheme.accentBlue
                            : AppTheme.colorSubtext,
                        size: 20),
                    const SizedBox(width: 12),
                    Text(
                      fmtData ?? 'Selecionar data',
                      style: TextStyle(
                        fontSize: 15,
                        color: _dataSelecionada != null
                            ? AppTheme.accentBlue
                            : AppTheme.colorSubtext,
                        fontWeight: _dataSelecionada != null
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right,
                        color: AppTheme.colorSubtext, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Endereço
            const Text('Endereco',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.colorSubtext)),
            const SizedBox(height: 8),
            if (_loadingEnderecos)
              const Center(
                  child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2)))
            else if (_enderecos.isEmpty)
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  context.push('/buscar-diaristas');
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.colorSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.colorBorder),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add_location_alt_outlined,
                          color: AppTheme.colorSubtext, size: 20),
                      SizedBox(width: 10),
                      Text('Nenhum endereco salvo — continuar sem filtro',
                          style: TextStyle(
                              fontSize: 14, color: AppTheme.colorSubtext)),
                    ],
                  ),
                ),
              )
            else
              DropdownButtonFormField<EnderecoCliente>(
                value: _enderecoSelecionado,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppTheme.colorBorder)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppTheme.colorBorder)),
                ),
                items: _enderecos
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text('${e.apelido} — ${e.logradouro}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14)),
                        ))
                    .toList(),
                onChanged: (e) => setState(() => _enderecoSelecionado = e),
              ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _buscar,
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54)),
              child: const Text('Ver profissionais disponiveis',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Servico rapido item ──────────────────────────────────────────────────────

class _ServicoRapidoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ServicoRapidoItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.colorSurface,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.colorBorder),
            ),
            child: Icon(icon, size: 26, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 8),
          Text(label,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _SolicitacaoCard extends StatelessWidget {
  final Solicitacao solicitacao;

  const _SolicitacaoCard({required this.solicitacao});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(solicitacao.status);
    final fmt = DateFormat("dd/MM 'as' HH:mm");

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.colorBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.cleaning_services, color: statusColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ServicoRegistry.labelFor(solicitacao.tipoLimpeza),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  solicitacao.endereco,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppTheme.colorSubtext, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  fmt.format(solicitacao.dataAgendada),
                  style: const TextStyle(
                      color: AppTheme.colorSubtext, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              solicitacao.getStatusLabel(),
              style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String s) => switch (s) {
        'aceita' => AppTheme.accentBlue,
        'em_andamento' => AppTheme.accentOrange,
        'finalizada' => AppTheme.successColor,
        'cancelada' => AppTheme.errorColor,
        _ => AppTheme.colorSubtext,
      };
}

class _DicaCard extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String descricao;
  final Color cor;

  const _DicaCard({
    required this.icon,
    required this.titulo,
    required this.descricao,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cor.withAlpha(12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cor.withAlpha(40)),
      ),
      child: Row(
        children: [
          Icon(icon, color: cor, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(descricao,
                    style: const TextStyle(
                        color: AppTheme.colorSubtext, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Aba Historico ────────────────────────────────────────────────────────────

class _HistoricoTab extends StatelessWidget {
  final List<Solicitacao> solicitacoes;

  const _HistoricoTab({required this.solicitacoes});

  @override
  Widget build(BuildContext context) {
    final historico = solicitacoes
        .where((s) => s.status == 'finalizada' || s.status == 'cancelada')
        .toList();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: const Text('Atividade'),
          floating: true,
          backgroundColor: AppTheme.colorBackground,
        ),
        if (historico.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 64, color: AppTheme.colorSubtext),
                  SizedBox(height: 16),
                  Text('Nenhum servico realizado ainda',
                      style: TextStyle(
                          color: AppTheme.colorSubtext, fontSize: 16)),
                ],
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final s = historico[i];
                final fmt = DateFormat("dd 'de' MMMM", 'pt_BR');
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.colorSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.cleaning_services_outlined,
                        color: AppTheme.colorSubtext),
                  ),
                  title: Text(ServicoRegistry.labelFor(s.tipoLimpeza),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(fmt.format(s.dataAgendada),
                      style: const TextStyle(
                          color: AppTheme.colorSubtext, fontSize: 13)),
                  trailing: s.precoEstimado != null
                      ? Text(
                          'R\$ ${s.precoEstimado!.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        )
                      : null,
                );
              },
              childCount: historico.length,
            ),
          ),
      ],
    );
  }
}

// ─── Aba Perfil ───────────────────────────────────────────────────────────────

class _PerfilTab extends StatelessWidget {
  final String nome;
  final VoidCallback onLogout;

  const _PerfilTab({required this.nome, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: const Text('Conta'),
          floating: true,
          backgroundColor: AppTheme.colorBackground,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),
                Text(nome,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text('Cliente',
                    style:
                        TextStyle(color: AppTheme.colorSubtext, fontSize: 14)),
                const SizedBox(height: 32),
                _MenuTile(
                  icon: Icons.person_outline,
                  label: 'Editar perfil',
                  onTap: () {},
                ),
                _MenuTile(
                  icon: Icons.history_outlined,
                  label: 'Historico de servicos',
                  onTap: () {},
                ),
                _MenuTile(
                  icon: Icons.help_outline,
                  label: 'Ajuda',
                  onTap: () {},
                ),
                const SizedBox(height: 16),
                _MenuTile(
                  icon: Icons.logout,
                  label: 'Sair',
                  onTap: onLogout,
                  isDestructive: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppTheme.errorColor : AppTheme.colorText;
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: color),
          title: Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w500)),
          trailing: isDestructive
              ? null
              : const Icon(Icons.chevron_right, color: AppTheme.colorSubtext),
          onTap: onTap,
        ),
        const Divider(height: 1),
      ],
    );
  }
}
