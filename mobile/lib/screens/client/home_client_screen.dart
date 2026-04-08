import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../models/solicitacao.dart';

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
    {'icon': Icons.apartment_outlined, 'label': 'Apartamento', 'tipo': 'apartamento'},
    {'icon': Icons.business_outlined, 'label': 'Comercial', 'tipo': 'comercial'},
    {'icon': Icons.cleaning_services_outlined, 'label': 'Faxina', 'tipo': 'faxina'},
    {'icon': Icons.window_outlined, 'label': 'Vidros', 'tipo': 'vidros'},
    {'icon': Icons.local_laundry_service_outlined, 'label': 'Lavanderia', 'tipo': 'lavanderia'},
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
                .where((s) => s.status == 'pendente' || s.status == 'aceita' || s.status == 'em_andamento')
                .toList(),
            isLoading: _isLoading,
            onRefresh: _loadData,
          ),
          _HistoricoTab(solicitacoes: _solicitacoes),
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
    final saudacao = hora < 12 ? 'Bom dia' : hora < 18 ? 'Boa tarde' : 'Boa noite';

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
                    onTap: () => context.push(
                      '/nova-solicitacao',
                      extra: {'tipo': s['tipo']},
                    ),
                  );
                },
              ),
            ),
          ),

          // Botao principal
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: ElevatedButton.icon(
                onPressed: () => context.push('/buscar-diaristas'),
                icon: const Icon(Icons.search),
                label: const Text('Encontrar Diaristas'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
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
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
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
                  solicitacao.tipoLimpeza ?? 'Servico de limpeza',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
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
                  title: Text(s.tipoLimpeza ?? 'Servico de limpeza',
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
                    style: TextStyle(
                        color: AppTheme.colorSubtext, fontSize: 14)),
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
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500)),
          trailing: isDestructive
              ? null
              : const Icon(Icons.chevron_right,
                  color: AppTheme.colorSubtext),
          onTap: onTap,
        ),
        const Divider(height: 1),
      ],
    );
  }
}

// ─── Widget Previews ─────────────────────────────────────────────────────────

@Preview(name: 'Home Cliente')
Widget homeClientPreview() => MultiProvider(
      providers: [
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => UserService()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const HomeClientScreen(),
      ),
    );