import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';

/// Painel Administrativo
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({Key? key}) : super(key: key);

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  // Estatisticas
  int _totalUsuarios = 0;
  int _totalClientes = 0;
  int _totalDiaristas = 0;
  int _totalSolicitacoes = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final userService = context.read<UserService>();
      final stats = await userService.getAdminStats();
      setState(() {
        _totalUsuarios = stats['total_usuarios'] ?? 0;
        _totalClientes = stats['total_clientes'] ?? 0;
        _totalDiaristas = stats['total_diaristas'] ?? 0;
        _totalSolicitacoes = stats['total_solicitacoes'] ?? 0;
      });
    } catch (_) {
      // Silencioso - estatisticas nao criticas
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
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            tooltip: 'Ver como Cliente',
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/client-home'),
          ),
          IconButton(
            tooltip: 'Ver como Diarista',
            icon: const Icon(Icons.cleaning_services_outlined),
            onPressed: () => context.push('/worker-home'),
          ),
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Usuarios',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Solicitacoes',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildUsuarios();
      case 2:
        return _buildSolicitacoes();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge admin
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield, size: 14, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'Administrador',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Visao Geral',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _buildStatCard(
                    'Usuarios',
                    _totalUsuarios.toString(),
                    Icons.people,
                    AppTheme.accentBlue,
                  ),
                  _buildStatCard(
                    'Clientes',
                    _totalClientes.toString(),
                    Icons.person,
                    AppTheme.secondaryColor,
                  ),
                  _buildStatCard(
                    'Diaristas',
                    _totalDiaristas.toString(),
                    Icons.cleaning_services,
                    AppTheme.accentOrange,
                  ),
                  _buildStatCard(
                    'Solicitacoes',
                    _totalSolicitacoes.toString(),
                    Icons.assignment,
                    AppTheme.primaryColor,
                  ),
                ],
              ),

            const SizedBox(height: 32),

            Text(
              'Acesso Rapido',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            _buildAccessCard(
              'Visao do Cliente',
              'Acesse o app como cliente',
              Icons.person_outline,
              AppTheme.accentBlue,
              () => context.push('/client-home'),
            ),
            const SizedBox(height: 12),
            _buildAccessCard(
              'Visao da Diarista',
              'Acesse o app como diarista',
              Icons.cleaning_services_outlined,
              AppTheme.accentOrange,
              () => context.push('/worker-home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(50), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.colorSubtext,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.colorBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppTheme.colorSubtext, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.colorSubtext),
          ],
        ),
      ),
    );
  }

  Widget _buildUsuarios() {
    return const _UsuariosTab();
  }

  Widget _buildSolicitacoes() {
    return const _SolicitacoesTab();
  }
}

// ─── Aba de usuarios ─────────────────────────────────────────────────────────

class _UsuariosTab extends StatefulWidget {
  const _UsuariosTab();

  @override
  State<_UsuariosTab> createState() => _UsuariosTabState();
}

class _UsuariosTabState extends State<_UsuariosTab> {
  List<Map<String, dynamic>> _usuarios = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsuarios();
  }

  Future<void> _loadUsuarios() async {
    setState(() => _isLoading = true);
    try {
      final userService = context.read<UserService>();
      final lista = await userService.getAllUsers();
      setState(() => _usuarios = lista);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_usuarios.isEmpty) {
      return const Center(child: Text('Nenhum usuario encontrado'));
    }

    return RefreshIndicator(
      onRefresh: _loadUsuarios,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _usuarios.length,
        itemBuilder: (context, index) {
          final u = _usuarios[index];
          final tipo = u['tipo_usuario'] as String? ?? '';
          final cor = tipo == 'admin'
              ? AppTheme.primaryColor
              : tipo == 'diarista'
                  ? AppTheme.accentOrange
                  : AppTheme.accentBlue;

          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
            leading: CircleAvatar(
              backgroundColor: cor.withAlpha(25),
              child: Text(
                (u['nome'] as String? ?? '?')[0].toUpperCase(),
                style: TextStyle(color: cor, fontWeight: FontWeight.w600),
              ),
            ),
            title: Text(u['nome'] as String? ?? ''),
            subtitle: Text(u['email'] as String? ?? ''),
            trailing: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cor.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tipo,
                style: TextStyle(
                    color: cor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Aba de solicitacoes ──────────────────────────────────────────────────────

class _SolicitacoesTab extends StatefulWidget {
  const _SolicitacoesTab();

  @override
  State<_SolicitacoesTab> createState() => _SolicitacoesTabState();
}

class _SolicitacoesTabState extends State<_SolicitacoesTab> {
  List<Map<String, dynamic>> _solicitacoes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSolicitacoes();
  }

  Future<void> _loadSolicitacoes() async {
    setState(() => _isLoading = true);
    try {
      final userService = context.read<UserService>();
      final lista = await userService.getAllSolicitacoes();
      setState(() => _solicitacoes = lista);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_solicitacoes.isEmpty) {
      return const Center(child: Text('Nenhuma solicitacao encontrada'));
    }

    return RefreshIndicator(
      onRefresh: _loadSolicitacoes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _solicitacoes.length,
        itemBuilder: (context, index) {
          final s = _solicitacoes[index];
          final status = s['status'] as String? ?? '';
          final statusColor = switch (status) {
            'finalizada' => AppTheme.successColor,
            'cancelada' => AppTheme.errorColor,
            'aceita' => AppTheme.accentBlue,
            'em_andamento' => AppTheme.accentOrange,
            _ => AppTheme.colorSubtext,
          };

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(s['descricao'] as String? ?? 'Sem descricao',
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(s['endereco'] as String? ?? ''),
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Widget Previews ─────────────────────────────────────────────────────────

@Preview(name: 'Admin Home')
Widget adminHomePreview() => MultiProvider(
      providers: [
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => UserService()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const AdminHomeScreen(),
      ),
    );