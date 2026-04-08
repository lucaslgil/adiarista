import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/diarista_perfil.dart';
import '../../services/user_service.dart';

class BuscarDiaristasScreen extends StatefulWidget {
  const BuscarDiaristasScreen({Key? key}) : super(key: key);

  @override
  State<BuscarDiaristasScreen> createState() => _BuscarDiaristasScreenState();
}

class _BuscarDiaristasScreenState extends State<BuscarDiaristasScreen> {
  final _searchController = TextEditingController();
  List<DiaristaPerfil> _diaristas = [];
  List<DiaristaPerfil> _filtradas = [];
  bool _isLoading = true;
  String? _tipoFiltro;
  double _avaliacaoMin = 0;
  double _precoMax = 1000;

  static const _tipos = [
    'Casa',
    'Apartamento',
    'Comercial',
    'Faxina',
    'Pos-obra',
    'Jardim',
  ];

  @override
  void initState() {
    super.initState();
    _carregarDiaristas();
    _searchController.addListener(_filtrar);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregarDiaristas() async {
    setState(() => _isLoading = true);
    try {
      final userService = context.read<UserService>();
      final lista = await userService.getDiaristasDisponiveis();
      if (mounted) {
        setState(() {
          _diaristas = lista;
          _filtradas = lista;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filtrar() {
    final texto = _searchController.text.toLowerCase();
    setState(() {
      _filtradas = _diaristas.where((d) {
        final matchTexto = texto.isEmpty ||
            d.regiao.toLowerCase().contains(texto) ||
            d.descricao.toLowerCase().contains(texto) ||
            d.especialidades.any((e) => e.toLowerCase().contains(texto));
        final matchAvaliacao = d.avaliacaoMedia >= _avaliacaoMin;
        final matchPreco = d.preco <= _precoMax;
        return matchTexto && matchAvaliacao && matchPreco;
      }).toList();
    });
  }

  void _abrirFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FiltrosSheet(
        avaliacaoMin: _avaliacaoMin,
        precoMax: _precoMax,
        tipoFiltro: _tipoFiltro,
        tipos: _tipos,
        onAplicar: (avaliacao, preco, tipo) {
          setState(() {
            _avaliacaoMin = avaliacao;
            _precoMax = preco;
            _tipoFiltro = tipo;
          });
          _filtrar();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.colorBackground,
      body: Column(
        children: [
          // Header fixo
          Container(
            color: AppTheme.colorBackground,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              bottom: 12,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Buscar por regiao ou especialidade...',
                          prefixIcon: const Icon(Icons.search,
                              color: AppTheme.colorSubtext),
                          filled: true,
                          fillColor: AppTheme.colorSurface,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.tune_outlined),
                      onPressed: _abrirFiltros,
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.colorSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Chips de tipo rapido
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: _tipos.length,
              itemBuilder: (_, i) {
                final t = _tipos[i];
                final selecionado = _tipoFiltro == t;
                return FilterChip(
                  label: Text(t),
                  selected: selecionado,
                  onSelected: (_) {
                    setState(() => _tipoFiltro = selecionado ? null : t);
                    _filtrar();
                  },
                  selectedColor: AppTheme.primaryColor,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: selecionado ? Colors.white : AppTheme.colorText,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Contador de resultados
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${_filtradas.length} diaristas encontradas',
                  style: const TextStyle(
                      color: AppTheme.colorSubtext, fontSize: 13),
                ),
              ],
            ),
          ),

          // Lista
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtradas.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off,
                                size: 56, color: AppTheme.colorSubtext),
                            SizedBox(height: 12),
                            Text('Nenhuma diarista encontrada',
                                style: TextStyle(
                                    color: AppTheme.colorSubtext, fontSize: 16)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _carregarDiaristas,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemCount: _filtradas.length,
                          itemBuilder: (context, i) =>
                              _DiaristaCard(diarista: _filtradas[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ─── Card da Diarista ─────────────────────────────────────────────────────────

class _DiaristaCard extends StatelessWidget {
  final DiaristaPerfil diarista;

  const _DiaristaCard({required this.diarista});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        '/nova-solicitacao',
        extra: {'diaristId': diarista.userId},
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.colorBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          diarista.regiao,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                      _Estrelas(avaliacao: diarista.avaliacaoMedia),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    diarista.descricao,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppTheme.colorSubtext, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (diarista.especialidades.isNotEmpty)
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: diarista.especialidades
                                .take(3)
                                .map((e) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.colorSurface,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color: AppTheme.colorBorder),
                                      ),
                                      child: Text(e,
                                          style: const TextStyle(fontSize: 11)),
                                    ))
                                .toList(),
                          ),
                        ),
                      Text(
                        'R\$ ${diarista.preco.toStringAsFixed(0)}/dia',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Estrelas extends StatelessWidget {
  final double avaliacao;

  const _Estrelas({required this.avaliacao});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 15, color: AppTheme.accentOrange),
        const SizedBox(width: 2),
        Text(
          avaliacao.toStringAsFixed(1),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// ─── Bottom Sheet de Filtros ──────────────────────────────────────────────────

class _FiltrosSheet extends StatefulWidget {
  final double avaliacaoMin;
  final double precoMax;
  final String? tipoFiltro;
  final List<String> tipos;
  final void Function(double avaliacao, double preco, String? tipo) onAplicar;

  const _FiltrosSheet({
    required this.avaliacaoMin,
    required this.precoMax,
    required this.tipoFiltro,
    required this.tipos,
    required this.onAplicar,
  });

  @override
  State<_FiltrosSheet> createState() => _FiltrosSheetState();
}

class _FiltrosSheetState extends State<_FiltrosSheet> {
  late double _avaliacao;
  late double _preco;
  String? _tipo;

  @override
  void initState() {
    super.initState();
    _avaliacao = widget.avaliacaoMin;
    _preco = widget.precoMax;
    _tipo = widget.tipoFiltro;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.colorBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Filtros',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          Text('Avaliacao minima: ${_avaliacao.toStringAsFixed(1)} ',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Slider(
            value: _avaliacao,
            min: 0,
            max: 5,
            divisions: 10,
            label: _avaliacao.toStringAsFixed(1),
            onChanged: (v) => setState(() => _avaliacao = v),
          ),
          const SizedBox(height: 8),
          Text('Preco maximo: R\$ ${_preco.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Slider(
            value: _preco,
            min: 50,
            max: 1000,
            divisions: 19,
            label: 'R\$ ${_preco.toStringAsFixed(0)}',
            onChanged: (v) => setState(() => _preco = v),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              widget.onAplicar(_avaliacao, _preco, _tipo);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
            child: const Text('Aplicar filtros'),
          ),
        ],
      ),
    );
  }
}
