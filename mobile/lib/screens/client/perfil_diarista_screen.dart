import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/diarista_perfil.dart';
import '../../services/user_service.dart';

class PerfilDiaristaScreen extends StatefulWidget {
  final String diaristaId;

  const PerfilDiaristaScreen({Key? key, required this.diaristaId})
      : super(key: key);

  @override
  State<PerfilDiaristaScreen> createState() => _PerfilDiaristaScreenState();
}

class _PerfilDiaristaScreenState extends State<PerfilDiaristaScreen> {
  DiaristaPerfil? _perfil;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final userService = context.read<UserService>();
      final perfil = await userService.getDiaristaPerfil(widget.diaristaId);
      if (mounted) setState(() => _perfil = perfil);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _abrirAgenda() {
    final p = _perfil;
    if (p == null) return;
    context.push('/agenda-cliente', extra: {
      'diaristaId': p.userId,
      'diaristaNome': p.nome.isNotEmpty ? p.nome : p.regiao,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.colorBackground,
      bottomNavigationBar: _isLoading || _perfil == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: ElevatedButton.icon(
                  onPressed: _abrirAgenda,
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text(
                    'Agendar com ${_perfil!.nome.isNotEmpty ? _perfil!.nome.split(' ').first : 'Diarista'}',
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _perfil == null
              ? _Vazio(onVoltar: () => Navigator.pop(context))
              : _Corpo(perfil: _perfil!),
    );
  }
}

class _Corpo extends StatelessWidget {
  final DiaristaPerfil perfil;
  const _Corpo({required this.perfil});

  @override
  Widget build(BuildContext context) {
    final nome = perfil.nome.isNotEmpty ? perfil.nome : perfil.regiao;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 230,
          pinned: true,
          backgroundColor: AppTheme.primaryColor,
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: CircleAvatar(
              backgroundColor: Colors.white.withAlpha(30),
              child: IconButton(
                icon:
                    const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1C1C1E), Color(0xFF2C2C2E)],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    _Avatar(nome: nome, size: 84),
                    const SizedBox(height: 12),
                    Text(
                      nome,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.white54, size: 14),
                        const SizedBox(width: 4),
                        Text(perfil.regiao,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: _MetricaCard(
                    icon: Icons.star_rounded,
                    valor: perfil.avaliacaoMedia > 0
                        ? perfil.avaliacaoMedia.toStringAsFixed(1)
                        : 'Nova',
                    label: 'Avaliacao',
                    cor: AppTheme.accentOrange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricaCard(
                    icon: Icons.payments_outlined,
                    valor: 'R\$ ${perfil.preco.toStringAsFixed(0)}',
                    label: 'Diaria',
                    cor: AppTheme.successColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricaCard(
                    icon: Icons.verified_outlined,
                    valor: perfil.ativo ? 'Ativa' : 'Inativa',
                    label: 'Status',
                    cor: perfil.ativo
                        ? AppTheme.accentBlue
                        : AppTheme.colorSubtext,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (perfil.descricao.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SecaoTitulo(texto: 'Sobre'),
                  const SizedBox(height: 8),
                  Text(perfil.descricao,
                      style: const TextStyle(
                          fontSize: 15,
                          color: AppTheme.colorText,
                          height: 1.5)),
                ],
              ),
            ),
          ),
        if (perfil.especialidades.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SecaoTitulo(texto: 'Especialidades'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: perfil.especialidades
                        .map((e) => _Chip(label: e))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SecaoTitulo(texto: 'Valores'),
                const SizedBox(height: 10),
                _TabelaPrecos(preco: perfil.preco),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withAlpha(12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accentBlue.withAlpha(40)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline,
                      color: AppTheme.accentBlue, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'A profissional analisa o pedido antes de confirmar. Voce sera notificado quando ela aceitar.',
                      style:
                          TextStyle(fontSize: 13, color: AppTheme.colorSubtext),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Vazio extends StatelessWidget {
  final VoidCallback onVoltar;
  const _Vazio({required this.onVoltar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.person_off_outlined,
            size: 64, color: AppTheme.colorSubtext),
        const SizedBox(height: 16),
        const Text('Perfil nao encontrado',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 24),
        TextButton(onPressed: onVoltar, child: const Text('Voltar')),
      ]),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String nome;
  final double size;
  const _Avatar({required this.nome, required this.size});

  String get _iniciais {
    final partes = nome.trim().split(' ');
    if (partes.length >= 2)
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    return nome.isNotEmpty ? nome[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withAlpha(20),
        border: Border.all(color: Colors.white.withAlpha(60), width: 2),
      ),
      child: Center(
        child: Text(
          _iniciais,
          style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.35,
              fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _SecaoTitulo extends StatelessWidget {
  final String texto;
  const _SecaoTitulo({required this.texto});

  @override
  Widget build(BuildContext context) => Text(texto,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700));
}

class _MetricaCard extends StatelessWidget {
  final IconData icon;
  final String valor;
  final String label;
  final Color cor;
  const _MetricaCard(
      {required this.icon,
      required this.valor,
      required this.label,
      required this.cor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: cor.withAlpha(15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cor.withAlpha(50)),
      ),
      child: Column(
        children: [
          Icon(icon, color: cor, size: 22),
          const SizedBox(height: 6),
          Text(valor,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: cor),
              overflow: TextOverflow.ellipsis,
              maxLines: 1),
          const SizedBox(height: 2),
          Text(label,
              style:
                  const TextStyle(fontSize: 11, color: AppTheme.colorSubtext)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.colorSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.colorBorder),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }
}

class _TabelaPrecos extends StatelessWidget {
  final double preco;
  const _TabelaPrecos({required this.preco});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colorSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.colorBorder),
      ),
      child: Column(
        children: [
          _LinhaPreco(
              label: 'Diaria integral (8h)',
              valor: 'R\$ ${preco.toStringAsFixed(0)}',
              destaque: true),
          const Divider(height: 1, color: AppTheme.colorBorder),
          _LinhaPreco(
              label: 'Meio periodo (4h)',
              valor: 'R\$ ${(preco * 0.6).toStringAsFixed(0)}'),
        ],
      ),
    );
  }
}

class _LinhaPreco extends StatelessWidget {
  final String label;
  final String valor;
  final bool destaque;
  const _LinhaPreco(
      {required this.label, required this.valor, this.destaque = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: destaque ? FontWeight.w600 : FontWeight.w400,
                  color: AppTheme.colorText)),
          Text(valor,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color:
                      destaque ? AppTheme.successColor : AppTheme.colorText)),
        ],
      ),
    );
  }
}
