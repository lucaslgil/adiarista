import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/diarista_perfil.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';

// Cache estático dos municípios brasileiros (IBGE). Carregado uma vez por sessão.
List<String>? _municipiosBrasilCache;

Future<List<String>> _carregarMunicipiosIbge() async {
  if (_municipiosBrasilCache != null) return _municipiosBrasilCache!;
  try {
    final uri = Uri.parse(
        'https://servicodados.ibge.gov.br/api/v1/localidades/municipios'
        '?orderBy=nome');
    final resp = await http.get(uri).timeout(const Duration(seconds: 10));
    if (resp.statusCode == 200) {
      final list = jsonDecode(resp.body) as List;
      _municipiosBrasilCache = list.map((e) {
        final nome = e['nome'] as String;
        final uf =
            (e['microrregiao']?['mesorregiao']?['UF']?['sigla'] as String?) ??
                '';
        return uf.isNotEmpty ? '$nome - $uf' : nome;
      }).toList();
    }
  } catch (_) {
    _municipiosBrasilCache = [];
  }
  return _municipiosBrasilCache ?? [];
}

// ============================================================================
// TELA: Locais de Atendimento da Diarista
//
// Permite configurar:
//   • Endereço base (residência) — via CEP + ViaCEP
//   • Lista de cidades atendidas  (Filtro Territorial — mandatório)
//   • Raio de ação em km          (Filtro de Proximidade — opcional)
//
// Combinações suportadas:
//   1. Apenas Cidade  → limitar_por_raio = false
//   2. Apenas Raio    → 1 cidade (detectada do CEP) + limitar_por_raio = true
//   3. Cidade + Raio  → múltiplas cidades + limitar_por_raio = true
// ============================================================================

class LocaisAtendimentoScreen extends StatefulWidget {
  const LocaisAtendimentoScreen({super.key});

  @override
  State<LocaisAtendimentoScreen> createState() =>
      _LocaisAtendimentoScreenState();
}

class _LocaisAtendimentoScreenState extends State<LocaisAtendimentoScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  // ── Endereço base ──────────────────────────────────────────────────────────
  final _cepCtrl = TextEditingController();
  final _logradouroCtrl = TextEditingController();
  final _bairroCtrl = TextEditingController();
  final _cidadeBaseCtrl = TextEditingController();
  final _estadoCtrl = TextEditingController();
  bool _buscandoCep = false;
  String? _erroCep;
  double? _lat;
  double? _lng;

  // ── Cidades atendidas ──────────────────────────────────────────────────────
  final List<String> _cidades = [];
  List<String> _municipios = [];

  // ── Raio de ação ───────────────────────────────────────────────────────────
  bool _limitarPorRaio = false;
  double _raioKm = 20.0;

  @override
  void initState() {
    super.initState();
    _cepCtrl.addListener(_onCepChanged);
    _carregar();
    _carregarMunicipiosIbge().then((lista) {
      if (mounted) setState(() => _municipios = lista);
    });
  }

  @override
  void dispose() {
    _cepCtrl.removeListener(_onCepChanged);
    _cepCtrl.dispose();
    _logradouroCtrl.dispose();
    _bairroCtrl.dispose();
    _cidadeBaseCtrl.dispose();
    _estadoCtrl.dispose();
    super.dispose();
  }

  // ─── Carga inicial ─────────────────────────────────────────────────────────
  Future<void> _carregar() async {
    final userId = context.read<AuthService>().currentUserId;
    if (userId == null) return;

    setState(() => _isLoading = true);
    try {
      final perfil =
          await context.read<UserService>().getDiaristaPerfil(userId);
      if (perfil != null && mounted) {
        setState(() {
          _lat = perfil.lat;
          _lng = perfil.lng;
          _cidades
            ..clear()
            ..addAll(perfil.cidadesAtendidas);
          _limitarPorRaio = perfil.limitarPorRaio;
          _raioKm = perfil.raioKm;
          // Tenta reconstruir cidade/estado a partir de regiao (fallback)
          if (perfil.lat == null && perfil.regiao.isNotEmpty) {
            _cidadeBaseCtrl.text = perfil.regiao;
          }
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── ViaCEP ────────────────────────────────────────────────────────────────
  String _apenasDigitos(String v) => v.replaceAll(RegExp(r'\D'), '');

  Future<void> _onCepChanged() async {
    final digits = _apenasDigitos(_cepCtrl.text);

    // Auto-formata 00000-000
    if (digits.length <= 8) {
      final formatted = digits.length > 5
          ? '${digits.substring(0, 5)}-${digits.substring(5)}'
          : digits;
      if (formatted != _cepCtrl.text) {
        _cepCtrl.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    }

    if (digits.length != 8) return;

    setState(() {
      _buscandoCep = true;
      _erroCep = null;
    });

    try {
      final uri = Uri.parse('https://viacep.com.br/ws/$digits/json/');
      final resp = await http.get(uri).timeout(const Duration(seconds: 6));
      if (!mounted) return;

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        if (data.containsKey('erro')) {
          setState(() => _erroCep = 'CEP não encontrado.');
        } else {
          _logradouroCtrl.text = data['logradouro'] as String? ?? '';
          _bairroCtrl.text = data['bairro'] as String? ?? '';
          final cidadeViaCep = data['localidade'] as String? ?? '';
          final ufViaCep = data['uf'] as String? ?? '';
          _cidadeBaseCtrl.text = cidadeViaCep;
          _estadoCtrl.text = ufViaCep;

          // Adiciona automaticamente a cidade base à lista no formato "Nome - UF"
          final cidadeComUf =
              ufViaCep.isNotEmpty ? '$cidadeViaCep - $ufViaCep' : cidadeViaCep;
          if (cidadeViaCep.isNotEmpty &&
              !_cidades.map(_normalizar).contains(_normalizar(cidadeComUf))) {
            setState(() => _cidades.add(cidadeComUf));
          }

          // Reset coords e inicia geocodificação assíncrona via Nominatim
          setState(() {
            _lat = null;
            _lng = null;
          });
          _geocodificarEndereco();
        }
      } else {
        setState(() => _erroCep = 'Erro ao buscar CEP. Tente novamente.');
      }
    } on Exception {
      if (mounted) setState(() => _erroCep = 'Sem conexão para buscar o CEP.');
    } finally {
      if (mounted) setState(() => _buscandoCep = false);
    }
  }

  // ─── Cidades ───────────────────────────────────────────────────────────────
  void _adicionarCidade(String nome) {
    final nova = nome.trim();
    if (nova.isEmpty) return;
    if (_cidades.map(_normalizar).contains(_normalizar(nova))) return;
    setState(() => _cidades.add(nova));
  }

  void _removerCidade(int index) {
    setState(() => _cidades.removeAt(index));
  }

  // ─── Geocodificação via Nominatim (OpenStreetMap) ──────────────────────────
  Future<void> _geocodificarEndereco() async {
    final logradouro = _logradouroCtrl.text.trim();
    final cidade = _cidadeBaseCtrl.text.trim();
    final estado = _estadoCtrl.text.trim();
    if (logradouro.isEmpty || cidade.isEmpty) return;

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'format': 'json',
        'limit': '1',
        'street': logradouro,
        'city': cidade,
        'state': estado,
        'country': 'Brazil',
      });
      final resp = await http.get(uri, headers: {
        'User-Agent': 'aDiarista/1.0',
        'Accept-Language': 'pt-BR,pt',
      }).timeout(const Duration(seconds: 8));

      if (!mounted) return;
      if (resp.statusCode == 200) {
        final list = jsonDecode(resp.body) as List;
        if (list.isNotEmpty) {
          final item = list.first as Map<String, dynamic>;
          final lat = double.tryParse(item['lat'] as String? ?? '');
          final lng = double.tryParse(item['lon'] as String? ?? '');
          if (lat != null && lng != null && mounted) {
            setState(() {
              _lat = lat;
              _lng = lng;
            });
          }
        }
      }
    } catch (_) {
      // Geocoding silencioso — mapa não aparece
    }
  }

  String _normalizar(String s) => s
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[áàãâä]'), 'a')
      .replaceAll(RegExp(r'[éèêë]'), 'e')
      .replaceAll(RegExp(r'[íìîï]'), 'i')
      .replaceAll(RegExp(r'[óòõôö]'), 'o')
      .replaceAll(RegExp(r'[úùûü]'), 'u')
      .replaceAll(RegExp(r'[ç]'), 'c');

  // ─── Salvar ────────────────────────────────────────────────────────────────
  Future<void> _salvar() async {
    if (_cidades.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Adicione ao menos uma cidade de atendimento.'),
        backgroundColor: AppTheme.errorColor,
      ));
      return;
    }

    final userId = context.read<AuthService>().currentUserId;
    if (userId == null) return;

    setState(() => _isSaving = true);
    try {
      await context.read<UserService>().updateDiaristaPerfil(
            userId: userId,
            latitude: _lat,
            longitude: _lng,
            cidadesAtendidas: _cidades,
            limitarPorRaio: _limitarPorRaio,
            raioKm: _raioKm,
            // regiao: primeira cidade como texto principal (para exibição no card)
            regiao: _cidades.isNotEmpty ? _cidades.first : null,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Locais de atendimento salvos!'),
          backgroundColor: AppTheme.successColor,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: AppTheme.errorColor,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─── Descrição do modo ativo ───────────────────────────────────────────────
  String get _descricaoModo {
    if (_cidades.isEmpty) return 'Nenhuma cidade configurada';
    if (!_limitarPorRaio) {
      return 'Atendimento em ${_cidades.length} cidade${_cidades.length > 1 ? 's' : ''} — sem limite de raio';
    }
    if (_cidades.length == 1) {
      return 'Raio de ${_raioKm.toStringAsFixed(0)} km a partir de ${_cidades.first}';
    }
    return '${_cidades.length} cidades + raio de ${_raioKm.toStringAsFixed(0)} km';
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.colorBackground,
      appBar: AppBar(
        title: const Text('Locais de Atendimento'),
        backgroundColor: AppTheme.colorBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            TextButton(
              onPressed: _salvar,
              child: const Text('Salvar',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              children: [
                // ── Resumo do modo ──────────────────────────────────────────
                _ModoAtual(descricao: _descricaoModo),
                const SizedBox(height: 24),

                // ── Seção 1: Endereço base ──────────────────────────────────
                _SectionHeader(
                  icon: Icons.home_work_outlined,
                  title: 'Seu endereço base',
                  subtitle:
                      'Origem para o cálculo de raio. Preenchido via CEP.',
                ),
                const SizedBox(height: 12),
                _CepField(
                  controller: _cepCtrl,
                  buscando: _buscandoCep,
                  erro: _erroCep,
                ),
                if (_logradouroCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _InfoEndereco(
                    logradouro: _logradouroCtrl.text,
                    bairro: _bairroCtrl.text,
                    cidade: _cidadeBaseCtrl.text,
                    estado: _estadoCtrl.text,
                    temCoordenadas: _lat != null,
                  ),
                ],
                const SizedBox(height: 28),

                // ── Seção 2: Cidades atendidas ──────────────────────────────
                _SectionHeader(
                  icon: Icons.location_city_outlined,
                  title: 'Cidades atendidas',
                  subtitle:
                      'Obrigatório. O cliente só verá você se seu endereço '
                      'de serviço estiver nessa lista.',
                ),
                const SizedBox(height: 12),
                _AutocompleteCidade(
                  municipios: _municipios,
                  cidadesJaAdicionadas: _cidades,
                  onAdicionar: _adicionarCidade,
                ),
                if (_cidades.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _ListaCidades(
                    cidades: _cidades,
                    onRemover: _removerCidade,
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  const _CidadesVazio(),
                ],
                const SizedBox(height: 28),

                // ── Seção 3: Raio de ação ───────────────────────────────────
                _SectionHeader(
                  icon: Icons.radar_outlined,
                  title: 'Raio de ação',
                  subtitle: 'Opcional. Quando ativado, você só aparece para '
                      'clientes dentro do raio configurado.',
                ),
                const SizedBox(height: 12),
                _RaioSection(
                  limitarPorRaio: _limitarPorRaio,
                  raioKm: _raioKm,
                  lat: _lat,
                  lng: _lng,
                  onToggle: (v) => setState(() => _limitarPorRaio = v),
                  onRaioChanged: (v) => setState(() => _raioKm = v),
                ),
                const SizedBox(height: 28),

                // ── Resumo das combinações possíveis ────────────────────────
                const _GuiaModos(),
              ],
            ),
    );
  }
}

// ─── Resumo do modo ativo ─────────────────────────────────────────────────────

class _ModoAtual extends StatelessWidget {
  final String descricao;
  const _ModoAtual({required this.descricao});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withAlpha(18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryColor.withAlpha(40)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              descricao,
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Cabeçalho de seção ───────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withAlpha(18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(
                      color: AppTheme.colorSubtext, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Campo de CEP ─────────────────────────────────────────────────────────────

class _CepField extends StatelessWidget {
  final TextEditingController controller;
  final bool buscando;
  final String? erro;

  const _CepField({
    required this.controller,
    required this.buscando,
    this.erro,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      maxLength: 9,
      decoration: InputDecoration(
        labelText: 'CEP da sua residência',
        hintText: '00000-000',
        counterText: '',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: AppTheme.colorSurface,
        prefixIcon: const Icon(Icons.location_on_outlined),
        suffixIcon: buscando
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : null,
        errorText: erro,
      ),
    );
  }
}

// ─── Info do endereço encontrado ──────────────────────────────────────────────

class _InfoEndereco extends StatelessWidget {
  final String logradouro;
  final String bairro;
  final String cidade;
  final String estado;
  final bool temCoordenadas;

  const _InfoEndereco({
    required this.logradouro,
    required this.bairro,
    required this.cidade,
    required this.estado,
    required this.temCoordenadas,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.successColor.withAlpha(40)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline,
              color: AppTheme.successColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$logradouro — $bairro',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text('$cidade / $estado',
                    style: const TextStyle(
                        color: AppTheme.colorSubtext, fontSize: 12)),
                if (!temCoordenadas) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Coordenadas serão atualizadas após salvar.',
                    style: TextStyle(
                        color: AppTheme.colorSubtext,
                        fontSize: 11,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Campo adicionar cidade ───────────────────────────────────────────────────

// ─── Autocomplete de município (IBGE) ──────────────────────────────────────────

class _AutocompleteCidade extends StatefulWidget {
  final List<String> municipios;
  final List<String> cidadesJaAdicionadas;
  final void Function(String) onAdicionar;

  const _AutocompleteCidade({
    required this.municipios,
    required this.cidadesJaAdicionadas,
    required this.onAdicionar,
  });

  @override
  State<_AutocompleteCidade> createState() => _AutocompleteCidadeState();
}

class _AutocompleteCidadeState extends State<_AutocompleteCidade> {
  String _normalizar(String s) => s
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[áàãâä]'), 'a')
      .replaceAll(RegExp(r'[éèêë]'), 'e')
      .replaceAll(RegExp(r'[íìîï]'), 'i')
      .replaceAll(RegExp(r'[óòõôö]'), 'o')
      .replaceAll(RegExp(r'[úùûü]'), 'u')
      .replaceAll(RegExp(r'[ç]'), 'c');

  Iterable<String> _sugestoes(TextEditingValue value) {
    final query = _normalizar(value.text);
    if (query.length < 2) return [];
    final jaAdicionadas = widget.cidadesJaAdicionadas.map(_normalizar).toSet();
    return widget.municipios
        .where((m) =>
            _normalizar(m).contains(query) &&
            !jaAdicionadas.contains(_normalizar(m)))
        .take(8);
  }

  void _confirmar(String value) {
    final nome = value.trim();
    if (nome.isEmpty) return;
    widget.onAdicionar(nome);
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: _sugestoes,
      fieldViewBuilder: (ctx, ctrl, focusNode, onSubmit) {
        return Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: ctrl,
                focusNode: focusNode,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Digite o município...',
                  filled: true,
                  fillColor: AppTheme.colorSurface,
                  prefixIcon: widget.municipios.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : const Icon(Icons.search_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onFieldSubmitted: (_) {
                  if (ctrl.text.isNotEmpty) {
                    _confirmar(ctrl.text);
                    ctrl.clear();
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                if (ctrl.text.isNotEmpty) {
                  _confirmar(ctrl.text);
                  ctrl.clear();
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(56, 52),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Icon(Icons.add),
            ),
          ],
        );
      },
      optionsViewBuilder: (ctx, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final option = options.elementAt(i);
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.location_on_outlined,
                        size: 18, color: AppTheme.accentBlue),
                    title: Text(option, style: const TextStyle(fontSize: 14)),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
      onSelected: (value) {
        widget.onAdicionar(value);
      },
    );
  }
}

// ─── Lista de cidades ─────────────────────────────────────────────────────────

class _ListaCidades extends StatelessWidget {
  final List<String> cidades;
  final void Function(int) onRemover;

  const _ListaCidades({required this.cidades, required this.onRemover});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(cidades.length, (i) {
        return Chip(
          label: Text(cidades[i],
              style:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          avatar: const Icon(Icons.location_on, size: 16),
          deleteIcon: const Icon(Icons.close, size: 14),
          onDeleted: () => onRemover(i),
          backgroundColor: AppTheme.accentBlue.withAlpha(20),
          side: BorderSide(color: AppTheme.accentBlue.withAlpha(50)),
          deleteIconColor: AppTheme.colorSubtext,
        );
      }),
    );
  }
}

// ─── Estado vazio de cidades ──────────────────────────────────────────────────

class _CidadesVazio extends StatelessWidget {
  const _CidadesVazio();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withAlpha(12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warningColor.withAlpha(40)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_outlined,
              color: AppTheme.warningColor, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Você não aparecerá nas buscas sem ao menos uma cidade cadastrada.',
              style: TextStyle(fontSize: 12, color: AppTheme.colorSubtext),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Seção de Raio de Ação ────────────────────────────────────────────────────

class _RaioSection extends StatelessWidget {
  final bool limitarPorRaio;
  final double raioKm;
  final double? lat;
  final double? lng;
  final ValueChanged<bool> onToggle;
  final ValueChanged<double> onRaioChanged;

  const _RaioSection({
    required this.limitarPorRaio,
    required this.raioKm,
    this.lat,
    this.lng,
    required this.onToggle,
    required this.onRaioChanged,
  });

  @override
  Widget build(BuildContext context) {
    final controls = Container(
      decoration: BoxDecoration(
        color: AppTheme.colorSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.colorBorder),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Limitar por raio de distância',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: const Text(
                'Apareço apenas para clientes próximos à minha base',
                style: TextStyle(fontSize: 12)),
            value: limitarPorRaio,
            onChanged: onToggle,
            activeColor: AppTheme.primaryColor,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          ),
          if (limitarPorRaio) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.radar,
                          size: 16, color: AppTheme.accentBlue),
                      const SizedBox(width: 6),
                      Text(
                        'Raio atual: ${raioKm.toStringAsFixed(0)} km',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppTheme.accentBlue),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: raioKm,
                    min: 5,
                    max: 100,
                    divisions: 19,
                    label: '${raioKm.toStringAsFixed(0)} km',
                    activeColor: AppTheme.accentBlue,
                    onChanged: onRaioChanged,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('5 km',
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.colorSubtext)),
                      Text('100 km',
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.colorSubtext)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        controls,
        if (limitarPorRaio) ...[
          const SizedBox(height: 12),
          if (lat != null && lng != null)
            _MapaRaio(lat: lat!, lng: lng!, raioKm: raioKm)
          else
            const _AvisoSemLocalizacao(),
        ],
      ],
    );
  }
}

// ─── Guia de modos ────────────────────────────────────────────────────────────

class _GuiaModos extends StatelessWidget {
  const _GuiaModos();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.colorSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.colorBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Como funciona o filtro?',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 12),
          _ModoItem(
            numero: '1',
            titulo: 'Somente por Cidade',
            desc:
                'Apareço para qualquer cliente na(s) cidade(s) cadastrada(s), '
                'independente da distância.',
            cor: AppTheme.successColor,
          ),
          const SizedBox(height: 10),
          _ModoItem(
            numero: '2',
            titulo: 'Somente por Raio',
            desc: 'Configure uma cidade + ative o raio. Apareço apenas para '
                'clientes dentro do raio a partir da sua base.',
            cor: AppTheme.accentBlue,
          ),
          const SizedBox(height: 10),
          _ModoItem(
            numero: '3',
            titulo: 'Cidade + Raio',
            desc: 'Múltiplas cidades com raio ativado. O cliente precisa estar '
                'em uma das cidades E dentro do raio.',
            cor: AppTheme.accentOrange,
          ),
        ],
      ),
    );
  }
}

class _ModoItem extends StatelessWidget {
  final String numero;
  final String titulo;
  final String desc;
  final Color cor;

  const _ModoItem({
    required this.numero,
    required this.titulo,
    required this.desc,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: cor.withAlpha(30),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(numero,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: cor)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              Text(desc,
                  style: const TextStyle(
                      color: AppTheme.colorSubtext, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Aviso sem localização ────────────────────────────────────────────────────

class _AvisoSemLocalizacao extends StatelessWidget {
  const _AvisoSemLocalizacao();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.colorSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.colorBorder),
      ),
      child: const Row(
        children: [
          Icon(Icons.map_outlined, color: AppTheme.colorSubtext, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Preencha o CEP da sua residência para visualizar o mapa de cobertura.',
              style: TextStyle(fontSize: 12, color: AppTheme.colorSubtext),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mapa de raio de ação (OpenStreetMap) ────────────────────────────────────

class _MapaRaio extends StatelessWidget {
  final double lat;
  final double lng;
  final double raioKm;

  const _MapaRaio({
    required this.lat,
    required this.lng,
    required this.raioKm,
  });

  static double _zoomForRadius(double km) {
    if (km >= 80) return 8;
    if (km >= 40) return 9;
    if (km >= 20) return 10;
    if (km >= 10) return 11;
    return 12;
  }

  @override
  Widget build(BuildContext context) {
    final center = LatLng(lat, lng);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.map_outlined, size: 16, color: AppTheme.accentBlue),
            SizedBox(width: 6),
            Text(
              'Área de cobertura',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppTheme.accentBlue),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 240,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: _zoomForRadius(raioKm),
                interactionOptions: const InteractionOptions(
                  flags:
                      InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.adiarista.app',
                ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: center,
                      radius: raioKm * 1000,
                      useRadiusInMeter: true,
                      color: AppTheme.accentBlue.withAlpha(45),
                      borderColor: AppTheme.accentBlue,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: center,
                      width: 36,
                      height: 36,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 6,
                              color: Colors.black.withAlpha(90),
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.home_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Mapa: © OpenStreetMap contributors',
          style: TextStyle(color: AppTheme.colorSubtext, fontSize: 10),
        ),
      ],
    );
  }
}
