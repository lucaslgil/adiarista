import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/preco_diarista.dart';
import '../../models/servico.dart';
import '../../services/agenda_service.dart';
import '../../services/auth_service.dart';
import '../../services/precos_service.dart';

// ============================================================================
// TELA: Configurar Preços da Diarista
// ============================================================================

class ConfigurarPrecosScreen extends StatefulWidget {
  const ConfigurarPrecosScreen({super.key});

  @override
  State<ConfigurarPrecosScreen> createState() => _ConfigurarPrecosScreenState();
}

class _ConfigurarPrecosScreenState extends State<ConfigurarPrecosScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  // Jornada de trabalho
  final _agendaService = AgendaService();
  TimeOfDay _horaInicio = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _horaFim = const TimeOfDay(hour: 17, minute: 0);
  List<int> _diasTrabalho = const [1, 2, 3, 4, 5]; // 0=Dom...6=Sab

  // Estado dos serviços (ativo/inativo)
  final Map<TipoServico, bool> _servicosAtivos = {};

  // Configurações de preço por serviço
  final Map<TipoServico, Map<String, dynamic>> _configs = {};
  final Map<TipoServico, double> _valoresMinimos = {};

  // Controladores de texto por serviço e campo
  final Map<TipoServico, Map<String, TextEditingController>> _controllers = {};

  // Modo de passar roupas ('por_hora' | 'por_peca')
  String _modoPassarRoupas = 'por_peca';

  @override
  void initState() {
    super.initState();
    _inicializarControladores();
    _carregarDados();
  }

  void _inicializarControladores() {
    for (final tipo in TipoServico.values) {
      _servicosAtivos[tipo] = false;
      _configs[tipo] = {};
      _valoresMinimos[tipo] = 0;
      _controllers[tipo] = {};
    }

    // Limpeza Residencial
    _controllers[TipoServico.limpezaResidencial] = {
      'preco_quarto': TextEditingController(),
      'preco_banheiro': TextEditingController(),
      'preco_sala': TextEditingController(),
      'preco_cozinha': TextEditingController(),
      'taxa_pet': TextEditingController(),
      'valor_minimo': TextEditingController(),
    };

    // Limpeza Comercial
    _controllers[TipoServico.limpezaComercial] = {
      'preco_por_m2': TextEditingController(),
      'valor_minimo': TextEditingController(),
    };

    // Lavar Roupas
    _controllers[TipoServico.lavarRoupas] = {
      'preco_por_hora': TextEditingController(),
      'valor_minimo': TextEditingController(),
    };

    // Passar Roupas
    _controllers[TipoServico.passarRoupas] = {
      'preco_por_hora': TextEditingController(),
      'preco_por_peca': TextEditingController(),
      'pecas_por_hora': TextEditingController(),
      'valor_minimo': TextEditingController(),
    };

    // Lavar + Passar
    _controllers[TipoServico.lavarEPassar] = {
      'preco_personalizado': TextEditingController(),
      'valor_minimo': TextEditingController(),
    };
  }

  @override
  void dispose() {
    for (final map in _controllers.values) {
      for (final ctrl in map.values) {
        ctrl.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    try {
      final userId = context.read<AuthService>().currentUserId;
      if (userId == null) return;

      final precosService = context.read<PrecosService>();
      final results = await Future.wait([
        precosService.getServicosDiarista(userId),
        precosService.getPrecosDiarista(userId),
        _agendaService.getConfiguracaoAgenda(userId),
      ]);

      final servicos = results[0] as List<ServicoDiarista>;
      final precos = results[1] as List<PrecoDiarista>;
      final jornada = results[2];

      if (!mounted) return;

      // Carregar jornada
      if (jornada != null) {
        // jornada is ConfiguracaoAgenda
        final cfg = jornada as dynamic;
        _horaInicio = cfg.horaInicioPadrao as TimeOfDay;
        _horaFim = cfg.horaFimPadrao as TimeOfDay;
        if (cfg.diasTrabalho != null) {
          _diasTrabalho = List<int>.from(cfg.diasTrabalho as List);
        }
      }

      // Mapear serviços ativos
      for (final servico in servicos) {
        _servicosAtivos[servico.tipoServico] = servico.ativo;
      }

      // Preencher controladores com valores existentes
      for (final preco in precos) {
        _valoresMinimos[preco.tipoServico] = preco.valorMinimo;
        _configs[preco.tipoServico] = Map.from(preco.configuracao);

        final ctrls = _controllers[preco.tipoServico]!;
        final cfg = preco.configuracao;

        _preencherControladores(preco.tipoServico, ctrls, cfg, preco.valorMinimo);

        if (preco.tipoServico == TipoServico.passarRoupas) {
          _modoPassarRoupas = cfg['modo'] as String? ?? 'por_peca';
        }
      }

      setState(() {});
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _preencherControladores(
    TipoServico tipo,
    Map<String, TextEditingController> ctrls,
    Map<String, dynamic> cfg,
    double valorMinimo,
  ) {
    void set(String key) {
      final v = (cfg[key] as num?)?.toDouble();
      if (v != null && v > 0) ctrls[key]?.text = v.toStringAsFixed(2);
    }

    switch (tipo) {
      case TipoServico.limpezaResidencial:
        set('preco_quarto');
        set('preco_banheiro');
        set('preco_sala');
        set('preco_cozinha');
        set('taxa_pet');
      case TipoServico.limpezaComercial:
        set('preco_por_m2');
      case TipoServico.lavarRoupas:
        set('preco_por_hora');
      case TipoServico.passarRoupas:
        set('preco_por_hora');
        set('preco_por_peca');
        set('pecas_por_hora');
      case TipoServico.lavarEPassar:
        set('preco_personalizado');
    }

    if (valorMinimo > 0) {
      ctrls['valor_minimo']?.text = valorMinimo.toStringAsFixed(2);
    }
  }

  Map<String, dynamic> _buildConfig(TipoServico tipo) {
    double? parse(String key) {
      final text = _controllers[tipo]![key]?.text.replaceAll(',', '.') ?? '';
      return double.tryParse(text);
    }

    return switch (tipo) {
      TipoServico.limpezaResidencial => {
          if (parse('preco_quarto') != null)
            'preco_quarto': parse('preco_quarto'),
          if (parse('preco_banheiro') != null)
            'preco_banheiro': parse('preco_banheiro'),
          if (parse('preco_sala') != null) 'preco_sala': parse('preco_sala'),
          if (parse('preco_cozinha') != null)
            'preco_cozinha': parse('preco_cozinha'),
          if (parse('taxa_pet') != null && parse('taxa_pet')! > 0)
            'taxa_pet': parse('taxa_pet'),
        },
      TipoServico.limpezaComercial => {
          if (parse('preco_por_m2') != null)
            'preco_por_m2': parse('preco_por_m2'),
        },
      TipoServico.lavarRoupas => {
          if (parse('preco_por_hora') != null)
            'preco_por_hora': parse('preco_por_hora'),
        },
      TipoServico.passarRoupas => {
          'modo': _modoPassarRoupas,
          if (_modoPassarRoupas == 'por_hora' &&
              parse('preco_por_hora') != null)
            'preco_por_hora': parse('preco_por_hora'),
          if (_modoPassarRoupas == 'por_peca' &&
              parse('preco_por_peca') != null)
            'preco_por_peca': parse('preco_por_peca'),
          if (_modoPassarRoupas == 'por_hora' &&
              parse('pecas_por_hora') != null)
            'pecas_por_hora': parse('pecas_por_hora'),
        },
      TipoServico.lavarEPassar => {
          if (parse('preco_personalizado') != null &&
              parse('preco_personalizado')! > 0)
            'preco_personalizado': parse('preco_personalizado'),
        },
    };
  }

  Future<void> _salvar() async {
    final userId = context.read<AuthService>().currentUserId;
    if (userId == null) return;

    setState(() => _isSaving = true);
    try {
      final precosService = context.read<PrecosService>();

      // Salvar jornada de trabalho
      await _agendaService.salvarConfiguracaoAgenda(
        diaristaId: userId,
        horaInicio: _horaInicio,
        horaFim: _horaFim,
        diasTrabalho: _diasTrabalho,
      );

      for (final tipo in TipoServico.values) {
        final ativo = _servicosAtivos[tipo] ?? false;

        // Salvar status do serviço
        await precosService.salvarServico(
          usuarioId: userId,
          tipo: tipo,
          ativo: ativo,
        );

        // Salvar preços somente se o serviço está ativo
        if (ativo) {
          final config = _buildConfig(tipo);
          final vMinText = _controllers[tipo]!['valor_minimo']?.text
                  .replaceAll(',', '.') ??
              '';
          final valorMinimo = double.tryParse(vMinText) ?? 0.0;

          await precosService.salvarPrecos(
            usuarioId: userId,
            tipo: tipo,
            configuracao: config,
            valorMinimo: valorMinimo,
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configurações salvas com sucesso!'),
            backgroundColor: AppTheme.successColor,
            duration: Duration(seconds: 2),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  bool get _temServicoComPrecoValido {
    for (final tipo in TipoServico.values) {
      if (_servicosAtivos[tipo] == true) {
        final config = _buildConfig(tipo);
        final vMinText = _controllers[tipo]!['valor_minimo']?.text
                .replaceAll(',', '.') ??
            '';
        final valorMinimo = double.tryParse(vMinText) ?? 0.0;
        if (valorMinimo > 0 &&
            CalculadoraPrecos.validarConfiguracao(tipo, config)) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.colorBackground,
      appBar: AppBar(
        title: const Text('Configurar Preços'),
        backgroundColor: AppTheme.colorBackground,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Banner de status
                _StatusBanner(temPrecoValido: _temServicoComPrecoValido),

                // Lista de serviços
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      // Jornada de trabalho
                      _JornadaCard(
                        horaInicio: _horaInicio,
                        horaFim: _horaFim,
                        diasTrabalho: _diasTrabalho,
                        onAlterarInicio: (t) =>
                            setState(() => _horaInicio = t),
                        onAlterarFim: (t) => setState(() => _horaFim = t),
                        onAlterarDias: (dias) =>
                            setState(() => _diasTrabalho = dias),
                      ),
                      const SizedBox(height: 8),
                      for (final tipo in TipoServico.values)
                        _ServicoCard(
                          tipo: tipo,
                          ativo: _servicosAtivos[tipo] ?? false,
                          controllers: _controllers[tipo]!,
                          modoPassarRoupas: _modoPassarRoupas,
                          onToggle: (val) =>
                              setState(() => _servicosAtivos[tipo] = val),
                          onModoPassarChanged: (modo) =>
                              setState(() => _modoPassarRoupas = modo),
                        ),
                    ],
                  ),
                ),

                // Botão salvar
                Container(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                    top: 12,
                  ),
                  decoration: const BoxDecoration(
                    color: AppTheme.colorBackground,
                    border: Border(
                      top: BorderSide(color: AppTheme.colorBorder),
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _salvar,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Salvar Configurações'),
                  ),
                ),
              ],
            ),
    );
  }
}

// ─── Banner de Status ─────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final bool temPrecoValido;
  const _StatusBanner({required this.temPrecoValido});

  @override
  Widget build(BuildContext context) {
    if (temPrecoValido) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: AppTheme.successColor.withAlpha(25),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline,
                color: AppTheme.successColor, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Preços configurados! Você pode ficar disponível.',
                style: TextStyle(
                    color: AppTheme.successColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppTheme.warningColor.withAlpha(25),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_outlined,
              color: AppTheme.warningColor, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Configure seus preços para começar a receber pedidos',
              style: TextStyle(
                  color: AppTheme.warningColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card de Serviço ──────────────────────────────────────────────────────────

class _ServicoCard extends StatelessWidget {
  final TipoServico tipo;
  final bool ativo;
  final Map<String, TextEditingController> controllers;
  final String modoPassarRoupas;
  final void Function(bool) onToggle;
  final void Function(String) onModoPassarChanged;

  const _ServicoCard({
    required this.tipo,
    required this.ativo,
    required this.controllers,
    required this.modoPassarRoupas,
    required this.onToggle,
    required this.onModoPassarChanged,
  });

  ServicoConfig get _config => ServicoRegistry.get(tipo);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.colorSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ativo ? AppTheme.primaryColor.withAlpha(80) : AppTheme.colorBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho do serviço
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: ativo
                        ? AppTheme.primaryColor
                        : AppTheme.colorBorder.withAlpha(120),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_config.icon,
                      color: ativo ? Colors.white : AppTheme.colorSubtext,
                      size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _config.label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      Text(
                        _config.unidade.label,
                        style: const TextStyle(
                            color: AppTheme.colorSubtext, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: ativo,
                  onChanged: onToggle,
                  activeColor: AppTheme.primaryColor,
                ),
              ],
            ),
          ),

          // Formulário de preços (visível apenas quando ativo)
          if (ativo) ...[
            const Divider(height: 1, color: AppTheme.colorBorder),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: _buildFormulario(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormulario() => switch (tipo) {
        TipoServico.limpezaResidencial => _FormResidencial(ctrls: controllers),
        TipoServico.limpezaComercial => _FormComercial(ctrls: controllers),
        TipoServico.lavarRoupas => _FormLavarRoupas(ctrls: controllers),
        TipoServico.passarRoupas => _FormPassarRoupas(
            ctrls: controllers,
            modo: modoPassarRoupas,
            onModoChanged: onModoPassarChanged,
          ),
        TipoServico.lavarEPassar => _FormLavarEPassar(ctrls: controllers),
      };
}

// ─── Formulários por Tipo de Serviço ─────────────────────────────────────────

class _FormResidencial extends StatelessWidget {
  final Map<String, TextEditingController> ctrls;
  const _FormResidencial({required this.ctrls});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Preço por cômodo (R\$)'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
                child: _PrecoField(
                    ctrl: ctrls['preco_quarto']!, label: 'Quarto', obrig: true)),
            const SizedBox(width: 8),
            Expanded(
                child: _PrecoField(
                    ctrl: ctrls['preco_banheiro']!,
                    label: 'Banheiro',
                    obrig: true)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
                child: _PrecoField(
                    ctrl: ctrls['preco_sala']!, label: 'Sala', obrig: true)),
            const SizedBox(width: 8),
            Expanded(
                child: _PrecoField(
                    ctrl: ctrls['preco_cozinha']!,
                    label: 'Cozinha',
                    obrig: true)),
          ],
        ),
        const SizedBox(height: 16),
        const _SectionLabel('Extras'),
        const SizedBox(height: 8),
        _PrecoField(
            ctrl: ctrls['taxa_pet']!,
            label: 'Taxa pet (opcional)',
            obrig: false),
        const SizedBox(height: 16),
        _ValorMinimoField(ctrl: ctrls['valor_minimo']!),
        const SizedBox(height: 8),
        _MultiplInfoBox(),
      ],
    );
  }
}

class _FormComercial extends StatelessWidget {
  final Map<String, TextEditingController> ctrls;
  const _FormComercial({required this.ctrls});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PrecoField(
            ctrl: ctrls['preco_por_m2']!,
            label: 'Preço por m² (R\$)',
            obrig: true),
        const SizedBox(height: 12),
        _ValorMinimoField(ctrl: ctrls['valor_minimo']!),
        const SizedBox(height: 8),
        _MultiplInfoBox(),
      ],
    );
  }
}

class _FormLavarRoupas extends StatelessWidget {
  final Map<String, TextEditingController> ctrls;
  const _FormLavarRoupas({required this.ctrls});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PrecoField(
            ctrl: ctrls['preco_por_hora']!,
            label: 'Preço por hora (R\$)',
            obrig: true),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.infoColor.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'Estimativa: Pequeno=1h • Médio=2h • Grande=3h',
            style: TextStyle(fontSize: 12, color: AppTheme.colorSubtext),
          ),
        ),
        const SizedBox(height: 12),
        _ValorMinimoField(ctrl: ctrls['valor_minimo']!),
      ],
    );
  }
}

class _FormPassarRoupas extends StatelessWidget {
  final Map<String, TextEditingController> ctrls;
  final String modo;
  final void Function(String) onModoChanged;

  const _FormPassarRoupas({
    required this.ctrls,
    required this.modo,
    required this.onModoChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Modo de cobrança'),
        const SizedBox(height: 8),
        Row(
          children: [
            _ModoChip(
              label: 'Por peça',
              selecionado: modo == 'por_peca',
              onTap: () => onModoChanged('por_peca'),
            ),
            const SizedBox(width: 8),
            _ModoChip(
              label: 'Por hora',
              selecionado: modo == 'por_hora',
              onTap: () => onModoChanged('por_hora'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (modo == 'por_peca') ...[
          _PrecoField(
              ctrl: ctrls['preco_por_peca']!,
              label: 'Preço por peça (R\$)',
              obrig: true),
        ] else ...[
          _PrecoField(
              ctrl: ctrls['preco_por_hora']!,
              label: 'Preço por hora (R\$)',
              obrig: true),
          const SizedBox(height: 8),
          _PrecoField(
              ctrl: ctrls['pecas_por_hora']!,
              label: 'Peças por hora (padrão: 20)',
              obrig: false,
              isInt: true),
        ],
        const SizedBox(height: 12),
        _ValorMinimoField(ctrl: ctrls['valor_minimo']!),
      ],
    );
  }
}

class _FormLavarEPassar extends StatelessWidget {
  final Map<String, TextEditingController> ctrls;
  const _FormLavarEPassar({required this.ctrls});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.infoColor.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'Se não definir preço personalizado, o sistema soma '
            'automaticamente Lavar + Passar.',
            style: TextStyle(fontSize: 12, color: AppTheme.colorSubtext),
          ),
        ),
        const SizedBox(height: 12),
        _PrecoField(
          ctrl: ctrls['preco_personalizado']!,
          label: 'Preço personalizado (opcional)',
          obrig: false,
        ),
        const SizedBox(height: 12),
        _ValorMinimoField(ctrl: ctrls['valor_minimo']!),
      ],
    );
  }
}

// ─── Componentes Internos ─────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: AppTheme.colorSubtext),
    );
  }
}

class _PrecoField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final bool obrig;
  final bool isInt;

  const _PrecoField({
    required this.ctrl,
    required this.label,
    required this.obrig,
    this.isInt = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isInt
          ? TextInputType.number
          : const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: isInt ? [FilteringTextInputFormatter.digitsOnly] : null,
      decoration: InputDecoration(
        labelText: obrig ? '$label *' : label,
        prefixText: isInt ? null : 'R\$ ',
        filled: true,
        fillColor: AppTheme.colorBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.colorBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.colorBorder),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
      ),
    );
  }
}

class _ValorMinimoField extends StatelessWidget {
  final TextEditingController ctrl;
  const _ValorMinimoField({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Valor mínimo *',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(width: 4),
            Tooltip(
              message:
                  'O cliente pagará pelo menos esse valor, mesmo se o cálculo for menor.',
              child: const Icon(Icons.help_outline,
                  size: 14, color: AppTheme.colorSubtext),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixText: 'R\$ ',
            hintText: '0,00',
            filled: true,
            fillColor: AppTheme.colorBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.colorBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.colorBorder),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            isDense: true,
          ),
        ),
      ],
    );
  }
}

class _ModoChip extends StatelessWidget {
  final String label;
  final bool selecionado;
  final VoidCallback onTap;

  const _ModoChip({
    required this.label,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selecionado ? AppTheme.primaryColor : AppTheme.colorBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                selecionado ? AppTheme.primaryColor : AppTheme.colorBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selecionado ? Colors.white : AppTheme.colorText,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _MultiplInfoBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.colorBorder.withAlpha(80),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Multiplicadores de sujeira (aplicados automaticamente)',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.colorSubtext),
          ),
          SizedBox(height: 4),
          Text(
            'Leve ×1,0  •  Médio ×1,2  •  Pesado ×1,5',
            style: TextStyle(fontSize: 11, color: AppTheme.colorSubtext),
          ),
        ],
      ),
    );
  }
}

// ─── Jornada de Trabalho ──────────────────────────────────────────────────────

class _JornadaCard extends StatelessWidget {
  final TimeOfDay horaInicio;
  final TimeOfDay horaFim;
  final List<int> diasTrabalho;
  final void Function(TimeOfDay) onAlterarInicio;
  final void Function(TimeOfDay) onAlterarFim;
  final void Function(List<int>) onAlterarDias;

  const _JornadaCard({
    required this.horaInicio,
    required this.horaFim,
    required this.diasTrabalho,
    required this.onAlterarInicio,
    required this.onAlterarFim,
    required this.onAlterarDias,
  });

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pick(
    BuildContext context,
    TimeOfDay initial,
    void Function(TimeOfDay) onConfirm,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) onConfirm(picked);
  }

  @override
  Widget build(BuildContext context) {
    final totalMin = (horaFim.hour * 60 + horaFim.minute) -
        (horaInicio.hour * 60 + horaInicio.minute);
    final duracaoStr = totalMin > 0
        ? '${totalMin ~/ 60}h${totalMin % 60 > 0 ? ' ${totalMin % 60}min' : ''}'
        : '—';

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.schedule_outlined,
                    color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Jornada de Trabalho',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    Text('Define quando você pode atender',
                        style: TextStyle(
                            color: AppTheme.colorSubtext, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HoraTile(
                  label: 'Início',
                  hora: _fmt(horaInicio),
                  onTap: () => _pick(context, horaInicio, onAlterarInicio),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HoraTile(
                  label: 'Término',
                  hora: _fmt(horaFim),
                  onTap: () => _pick(context, horaFim, onAlterarFim),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Jornada total: $duracaoStr',
            style: const TextStyle(
                color: AppTheme.colorSubtext, fontSize: 12),
          ),
          const SizedBox(height: 14),
          const Text(
            'Dias de trabalho',
            style: TextStyle(fontSize: 12, color: AppTheme.colorSubtext),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              // i=0=Dom, 1=Seg...6=Sab
              const labels = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
              final ativo = diasTrabalho.contains(i);
              return GestureDetector(
                onTap: () {
                  final nova = List<int>.from(diasTrabalho);
                  if (ativo) {
                    nova.remove(i);
                  } else {
                    nova.add(i);
                    nova.sort();
                  }
                  onAlterarDias(nova);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: ativo
                        ? AppTheme.primaryColor
                        : AppTheme.colorBackground,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ativo
                          ? AppTheme.primaryColor
                          : AppTheme.colorBorder,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ativo ? Colors.white : AppTheme.colorSubtext,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _HoraTile extends StatelessWidget {
  final String label;
  final String hora;
  final VoidCallback onTap;

  const _HoraTile({
    required this.label,
    required this.hora,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.colorBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.colorBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppTheme.colorSubtext, fontSize: 11)),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(hora,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 18)),
                const Spacer(),
                const Icon(Icons.edit_outlined,
                    size: 15, color: AppTheme.colorSubtext),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
