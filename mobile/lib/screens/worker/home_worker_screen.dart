import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/diarista_perfil.dart';
import '../../models/servico.dart';
import '../../models/solicitacao.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';

class HomeWorkerScreen extends StatefulWidget {
  const HomeWorkerScreen({Key? key}) : super(key: key);

  @override
  State<HomeWorkerScreen> createState() => _HomeWorkerScreenState();
}

class _HomeWorkerScreenState extends State<HomeWorkerScreen> {
  int _selectedIndex = 0;
  bool _disponivel = true;
  bool _isLoading = false;
  List<Solicitacao> _pedidosPendentes = [];
  List<Solicitacao> _meusPedidos = [];
  DiaristaPerfil? _perfil;
  String _nomeDiarista = 'Diarista';

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
        final results = await Future.wait([
          userService.getSolicitacoesPendentes(''),
          userService.getSolicitacoesDiarista(userId),
          userService.getDiaristaPerfil(userId),
          userService.getUserById(userId),
        ]);

        if (mounted) {
          setState(() {
            _pedidosPendentes = (results[0] as List<Solicitacao>)
                .where((s) => s.diaristId == null)
                .toList();
            _meusPedidos = results[1] as List<Solicitacao>;
            _perfil = results[2] as DiaristaPerfil?;
            final user = results[3];
            if (user != null) {
              _nomeDiarista = (user as dynamic).nome.split(' ').first;
            }
            if (_perfil != null) _disponivel = _perfil!.ativo;
          });
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleDisponibilidade(bool valor) async {
    final authService = context.read<AuthService>();
    final userService = context.read<UserService>();
    final userId = authService.currentUserId;
    if (userId == null) return;

    setState(() => _disponivel = valor);
    try {
      await userService.updateDiaristaPerfil(userId: userId, ativo: valor);
    } catch (_) {
      setState(() => _disponivel = !valor);
    }
  }

  Future<void> _aceitarPedido(Solicitacao s) async {
    final userService = context.read<UserService>();
    final authService = context.read<AuthService>();
    final userId = authService.currentUserId;
    if (userId == null) return;

    try {
      await userService.aceitarSolicitacao(solicitacaoId: s.id, diaristId: userId);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido aceito com sucesso!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
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
            nomeDiarista: _nomeDiarista,
            disponivel: _disponivel,
            isLoading: _isLoading,
            pedidosPendentes: _pedidosPendentes,
            onToggleDisponibilidade: _toggleDisponibilidade,
            onAceitar: _aceitarPedido,
            onRefresh: _loadData,
          ),
          _MeusPedidosTab(pedidos: _meusPedidos),
          _PerfilWorkerTab(
            nome: _nomeDiarista,
            perfil: _perfil,
            onLogout: _handleLogout,
          ),
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
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work),
            label: 'Meus Trabalhos',
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

// ─── Aba Home: Pedidos Disponiveis ────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  final String nomeDiarista;
  final bool disponivel;
  final bool isLoading;
  final List<Solicitacao> pedidosPendentes;
  final void Function(bool) onToggleDisponibilidade;
  final void Function(Solicitacao) onAceitar;
  final VoidCallback onRefresh;

  const _HomeTab({
    required this.nomeDiarista,
    required this.disponivel,
    required this.isLoading,
    required this.pedidosPendentes,
    required this.onToggleDisponibilidade,
    required this.onAceitar,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              color: disponivel ? AppTheme.primaryColor : AppTheme.colorSurface,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 24,
                right: 24,
                bottom: 24,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ola, $nomeDiarista',
                            style: TextStyle(
                              color: disponivel ? Colors.white70 : AppTheme.colorSubtext,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            disponivel ? 'Voce esta disponivel' : 'Voce esta offline',
                            style: TextStyle(
                              color: disponivel ? Colors.white : AppTheme.colorText,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      // Toggle disponibilidade
                      GestureDetector(
                        onTap: () => onToggleDisponibilidade(!disponivel),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 72,
                          height: 40,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: disponivel
                                ? Colors.white.withAlpha(30)
                                : AppTheme.colorBorder,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: disponivel
                                  ? Colors.white.withAlpha(60)
                                  : AppTheme.colorBorder,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: disponivel
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: disponivel
                                      ? Colors.white
                                      : AppTheme.colorSubtext,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  disponivel ? Icons.check : Icons.close,
                                  size: 16,
                                  color: disponivel
                                      ? AppTheme.primaryColor
                                      : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (disponivel) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.circle,
                            size: 8, color: AppTheme.successColor),
                        const SizedBox(width: 6),
                        Text(
                          '${pedidosPendentes.length} pedido(s) disponivel(is)',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Status offline
          if (!disponivel)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(Icons.wifi_off_outlined,
                        size: 64, color: AppTheme.colorSubtext),
                    const SizedBox(height: 16),
                    const Text(
                      'Voce esta offline',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ative sua disponibilidade para receber pedidos',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppTheme.colorSubtext, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => onToggleDisponibilidade(true),
                      child: const Text('Ficar disponivel'),
                    ),
                  ],
                ),
              ),
            )
          else if (isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (pedidosPendentes.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inbox_outlined,
                        size: 64, color: AppTheme.colorSubtext),
                    SizedBox(height: 16),
                    Text(
                      'Nenhum pedido por enquanto',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Novos pedidos apareceram aqui quando disponivel',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppTheme.colorSubtext, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Text(
                  'Pedidos disponiveis',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: _PedidoCard(
                    solicitacao: pedidosPendentes[i],
                    onAceitar: () => onAceitar(pedidosPendentes[i]),
                  ),
                ),
                childCount: pedidosPendentes.length,
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _PedidoCard extends StatelessWidget {
  final Solicitacao solicitacao;
  final VoidCallback onAceitar;

  const _PedidoCard({required this.solicitacao, required this.onAceitar});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat("EEE, dd/MM 'as' HH:mm", 'pt_BR');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.colorBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tipo + data
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.colorSurface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        ServicoRegistry.labelFor(solicitacao.tipoLimpeza),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      fmt.format(solicitacao.dataAgendada),
                      style: const TextStyle(
                          color: AppTheme.colorSubtext, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Endereco
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 18, color: AppTheme.colorSubtext),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        solicitacao.endereco,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Descricao
                Text(
                  solicitacao.descricao,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppTheme.colorSubtext, fontSize: 13),
                ),
                if (solicitacao.precoEstimado != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.attach_money,
                          size: 18, color: AppTheme.successColor),
                      Text(
                        'R\$ ${solicitacao.precoEstimado!.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppTheme.successColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Botoes
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      foregroundColor: AppTheme.errorColor,
                      side:
                          const BorderSide(color: AppTheme.errorColor),
                    ),
                    child: const Text('Recusar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: onAceitar,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    child: const Text('Aceitar pedido'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Aba Meus Trabalhos ───────────────────────────────────────────────────────

class _MeusPedidosTab extends StatelessWidget {
  final List<Solicitacao> pedidos;

  const _MeusPedidosTab({required this.pedidos});

  @override
  Widget build(BuildContext context) {
    final ativos = pedidos
        .where((s) => s.status == 'aceita' || s.status == 'em_andamento')
        .toList();
    final concluidos =
        pedidos.where((s) => s.status == 'finalizada').toList();
    final fmt = DateFormat("dd/MM 'as' HH:mm");

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: const Text('Meus Trabalhos'),
          floating: true,
          backgroundColor: AppTheme.colorBackground,
        ),
        if (pedidos.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.work_outline,
                      size: 64, color: AppTheme.colorSubtext),
                  SizedBox(height: 16),
                  Text('Nenhum trabalho ainda',
                      style: TextStyle(
                          color: AppTheme.colorSubtext, fontSize: 16)),
                ],
              ),
            ),
          )
        else ...[
          if (ativos.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Text('Em andamento',
                    style: Theme.of(context).textTheme.titleLarge),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _TrabalhoTile(
                  solicitacao: ativos[i],
                  cor: AppTheme.accentBlue,
                  fmtData: fmt,
                ),
                childCount: ativos.length,
              ),
            ),
          ],
          if (concluidos.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Text('Concluidos',
                    style: Theme.of(context).textTheme.titleLarge),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _TrabalhoTile(
                  solicitacao: concluidos[i],
                  cor: AppTheme.successColor,
                  fmtData: fmt,
                ),
                childCount: concluidos.length,
              ),
            ),
          ],
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _TrabalhoTile extends StatelessWidget {
  final Solicitacao solicitacao;
  final Color cor;
  final DateFormat fmtData;

  const _TrabalhoTile({
    required this.solicitacao,
    required this.cor,
    required this.fmtData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
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
              color: cor.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.cleaning_services, color: cor),
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
                Text(
                  fmtData.format(solicitacao.dataAgendada),
                  style: const TextStyle(
                      color: AppTheme.colorSubtext, fontSize: 12),
                ),
              ],
            ),
          ),
          if (solicitacao.precoEstimado != null)
            Text(
              'R\$ ${solicitacao.precoEstimado!.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
        ],
      ),
    );
  }
}

// ─── Aba Perfil Worker ────────────────────────────────────────────────────────

class _PerfilWorkerTab extends StatelessWidget {
  final String nome;
  final DiaristaPerfil? perfil;
  final VoidCallback onLogout;

  const _PerfilWorkerTab({
    required this.nome,
    required this.perfil,
    required this.onLogout,
  });

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
                Stack(
                  children: [
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
                    if (perfil != null)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.successColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified,
                              color: Colors.white, size: 12),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(nome,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                const Text('Diarista',
                    style: TextStyle(
                        color: AppTheme.colorSubtext, fontSize: 14)),

                if (perfil != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _EstatCard(
                        label: 'Avaliacao',
                        valor: perfil!.avaliacaoMedia.toStringAsFixed(1),
                        icon: Icons.star_rounded,
                        cor: AppTheme.accentOrange,
                      ),
                      const SizedBox(width: 16),
                      _EstatCard(
                        label: 'Preco/dia',
                        valor: 'R\$ ${perfil!.preco.toStringAsFixed(0)}',
                        icon: Icons.attach_money,
                        cor: AppTheme.successColor,
                      ),
                      const SizedBox(width: 16),
                      _EstatCard(
                        label: 'Regiao',
                        valor: perfil!.regiao,
                        icon: Icons.location_on,
                        cor: AppTheme.accentBlue,
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 32),

                _MenuTile(
                  icon: Icons.person_outline,
                  label: 'Editar perfil profissional',
                  onTap: () {},
                ),
                _MenuTile(
                  icon: Icons.star_border_outlined,
                  label: 'Minhas avaliacoes',
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

class _EstatCard extends StatelessWidget {
  final String label;
  final String valor;
  final IconData icon;
  final Color cor;

  const _EstatCard({
    required this.label,
    required this.valor,
    required this.icon,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withAlpha(30)),
      ),
      child: Column(
        children: [
          Icon(icon, color: cor, size: 20),
          const SizedBox(height: 4),
          Text(valor,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.colorSubtext, fontSize: 11)),
        ],
      ),
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
                  color: color, fontWeight: FontWeight.w500)),
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

