import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../models/solicitacao.dart';

/// Tela Home da Diarista
class HomeWorkerScreen extends StatefulWidget {
  const HomeWorkerScreen({Key? key}) : super(key: key);

  @override
  State<HomeWorkerScreen> createState() => _HomeWorkerScreenState();
}

class _HomeWorkerScreenState extends State<HomeWorkerScreen> {
  int _selectedIndex = 0;
  bool _isLoading = false;
  List<Solicitacao> _solicitacoesPendentes = [];
  List<Solicitacao> _solicitacoesAceitas = [];

  @override
  void initState() {
    super.initState();
    _loadSolicitacoes();
  }

  /// Carregar solicitações
  Future<void> _loadSolicitacoes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = context.read<AuthService>();
      final userService = context.read<UserService>();
      final userId = authService.currentUserId;

      if (userId != null) {
        // Carregar solicitações pendentes (disponíveis)
        final pendentes = await userService.getSolicitacoesPendentes('');
        
        // Carregar solicitações aceitas
        final aceitas = await userService.getSolicitacoesDiarista(userId);
        
        setState(() {
          _solicitacoesPendentes = pendentes;
          _solicitacoesAceitas = aceitas;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar solicitações: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Aceitar solicitação
  Future<void> _aceitarSolicitacao(Solicitacao solicitacao) async {
    try {
      final authService = context.read<AuthService>();
      final userService = context.read<UserService>();
      final userId = authService.currentUserId;

      if (userId != null) {
        await userService.aceitarSolicitacao(
          solicitacaoId: solicitacao.id,
          diaristId: userId,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Solicitação aceita!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadSolicitacoes();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao aceitar: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  /// Fazer logout
  Future<void> _handleLogout() async {
    try {
      final authService = context.read<AuthService>();
      await authService.logout();
      
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao fazer logout: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('aDiarista - Diarista'),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Disponíveis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Meus Serviços',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildSolicitacoesDisponiveisTab();
      case 1:
        return _buildMeusServicosTab();
      case 2:
        return _buildPerfilTab();
      default:
        return _buildSolicitacoesDisponiveisTab();
    }
  }

  /// Aba de solicitações disponíveis
  Widget _buildSolicitacoesDisponiveisTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_solicitacoesPendentes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma solicitação disponível',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Atualize para ver novos serviços',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSolicitacoes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _solicitacoesPendentes.length,
        itemBuilder: (context, index) {
          final solicitacao = _solicitacoesPendentes[index];
          return _buildSolicitacaoDisponivel(solicitacao);
        },
      ),
    );
  }

  /// Card de solicitação disponível
  Widget _buildSolicitacaoDisponivel(Solicitacao solicitacao) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              solicitacao.tipoLimpeza ?? 'Serviço de Limpeza',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              solicitacao.endereco,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            if (solicitacao.precoEstimado != null)
              Text(
                'Preço estimado: R\$ ${solicitacao.precoEstimado?.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: Ver detalhes
                    },
                    child: const Text('Ver Detalhes'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _aceitarSolicitacao(solicitacao);
                    },
                    child: const Text('Aceitar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Aba de meus serviços
  Widget _buildMeusServicosTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_solicitacoesAceitas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.done_all_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum serviço aceito',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _solicitacoesAceitas.length,
      itemBuilder: (context, index) {
        final solicitacao = _solicitacoesAceitas[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              solicitacao.tipoLimpeza ?? 'Serviço',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(solicitacao.endereco),
                const SizedBox(height: 4),
                Text(
                  'Status: ${solicitacao.getStatusLabel()}',
                  style: TextStyle(
                    color: _getStatusColor(solicitacao.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Aba de perfil
  Widget _buildPerfilTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Seu Perfil',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _handleLogout,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Sair da Conta'),
          ),
        ],
      ),
    );
  }

  /// Obter cor do status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pendente':
        return AppTheme.warningColor;
      case 'aceita':
        return AppTheme.infoColor;
      case 'em_andamento':
        return AppTheme.infoColor;
      case 'finalizada':
        return AppTheme.successColor;
      case 'cancelada':
        return AppTheme.errorColor;
      default:
        return Colors.grey;
    }
  }
}
