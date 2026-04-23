import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/endereco_cliente.dart';
import '../../models/preco_diarista.dart';
import '../../models/servico.dart';
import '../../services/agenda_service.dart';
import '../../services/auth_service.dart';
import '../../services/endereco_service.dart';
import '../../services/precos_service.dart';
import '../../services/user_service.dart';

class NovaSolicitacaoScreen extends StatefulWidget {
  final String? tipoInicial;
  final String? diaristIdInicial;

  const NovaSolicitacaoScreen({
    Key? key,
    this.tipoInicial,
    this.diaristIdInicial,
  }) : super(key: key);

  @override
  State<NovaSolicitacaoScreen> createState() => _NovaSolicitacaoScreenState();
}

class _NovaSolicitacaoScreenState extends State<NovaSolicitacaoScreen> {
  int _etapa = 0;
  bool _isLoading = false;

  // Dados do formulario
  TipoServico? _tipoSelecionado;
  Map<String, dynamic> _parametros = {};
  final _enderecoController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _observacoesController = TextEditingController();
  DateTime? _dataHora;
  double? _precoEstimado;
  int? _duracaoMinutos;

  @override
  void initState() {
    super.initState();
    if (widget.tipoInicial != null) {
      _tipoSelecionado = TipoServico.fromValue(widget.tipoInicial);
      if (_tipoSelecionado != null) _etapa = 1;
    }
  }

  @override
  void dispose() {
    _enderecoController.dispose();
    _descricaoController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  bool get _podeAvancar => switch (_etapa) {
        0 => _tipoSelecionado != null,
        1 => _tipoSelecionado != null &&
            ServicoRegistry.get(_tipoSelecionado!)
                    .validarParametros(_parametros) ==
                null,
        2 => _enderecoController.text.trim().isNotEmpty,
        3 => _dataHora != null,
        4 => _descricaoController.text.trim().isNotEmpty,
        _ => false,
      };

  void _avancar() {
    if (_etapa == 1) {
      // Calcular duração estimada
      if (_tipoSelecionado != null) {
        setState(() {
          _duracaoMinutos =
              DuracaoServico.calcularMinutos(_tipoSelecionado!, _parametros);
        });
      }
      // Calcular estimativa de preço (quando diarista conhecida)
      if (widget.diaristIdInicial != null) {
        _calcularEstimativa();
      }
    }
    if (_etapa < 5) {
      setState(() => _etapa++);
    }
  }

  Future<void> _calcularEstimativa() async {
    final diaristId = widget.diaristIdInicial;
    final tipo = _tipoSelecionado;
    if (diaristId == null || tipo == null) return;
    try {
      final precosService = context.read<PrecosService>();
      final estimativa = await precosService.calcularEstimativa(
        usuarioDiaristaId: diaristId,
        tipo: tipo,
        parametrosCliente: _parametros,
      );
      if (mounted && estimativa != null) {
        setState(() => _precoEstimado = estimativa);
      }
    } catch (_) {
      // Falha silenciosa: estimativa não crítica
    }
  }

  void _voltar() {
    if (_etapa > 0) {
      setState(() => _etapa--);
    } else {
      context.pop();
    }
  }

  Future<void> _confirmar() async {
    final authService = context.read<AuthService>();
    final userService = context.read<UserService>();
    final clienteId = authService.currentUserId;

    if (clienteId == null) return;

    setState(() => _isLoading = true);

    try {
      await userService.criarSolicitacao(
        clienteId: clienteId,
        dataAgendada: _dataHora!,
        endereco: _enderecoController.text.trim(),
        descricao: _descricaoController.text.trim(),
        observacoes: _observacoesController.text.trim().isNotEmpty
            ? _observacoesController.text.trim()
            : null,
        tipoLimpeza: _tipoSelecionado?.value,
        parametros: _parametros.isEmpty ? null : Map.from(_parametros),
        precoEstimado: _precoEstimado,
        duracaoMinutos: _duracaoMinutos,
      );

      if (mounted) {
        _mostrarSucesso();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar solicitacao: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarSucesso() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppTheme.successColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),
            const Text(
              'Pedido enviado!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Seu pedido foi enviado com sucesso. Em breve uma diarista aceitara o servico.',
              style: TextStyle(color: AppTheme.colorSubtext, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/client-home');
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Ir para inicio'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.colorBackground,
      appBar: AppBar(
        title: const Text('Nova solicitacao'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _voltar,
        ),
        backgroundColor: AppTheme.colorBackground,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Barra de progresso
          Container(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Column(
              children: [
                Row(
                  children: List.generate(5, (i) {
                    final ativo = i <= _etapa;
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
                        decoration: BoxDecoration(
                          color: ativo
                              ? AppTheme.primaryColor
                              : AppTheme.colorBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _rotuloPasso(_etapa),
                    style: const TextStyle(
                        color: AppTheme.colorSubtext, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // Conteudo da etapa
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildEtapa(),
            ),
          ),

          // Botao de acao
          Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              top: 12,
            ),
            child: ElevatedButton(
              onPressed: (_podeAvancar && !_isLoading)
                  ? (_etapa == 4 ? _confirmar : _avancar)
                  : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_etapa == 4 ? 'Confirmar pedido' : 'Continuar'),
            ),
          ),
        ],
      ),
    );
  }

  String _rotuloPasso(int etapa) => switch (etapa) {
        0 => 'Passo 1 de 5 — Tipo de serviço',
        1 => 'Passo 2 de 5 — Detalhes do serviço',
        2 => 'Passo 3 de 5 — Endereço',
        3 => 'Passo 4 de 5 — Data e hora',
        4 => 'Passo 5 de 5 — Descrição',
        _ => 'Confirmação',
      };

  Widget _buildEtapa() => switch (_etapa) {
        0 => _EtapaTipo(
            tipoSelecionado: _tipoSelecionado,
            onSelecionar: (t) => setState(() {
              _tipoSelecionado = t;
              _parametros = _defaultParams(t);
            }),
          ),
        1 => _EtapaParametros(
            tipo: _tipoSelecionado!,
            parametros: _parametros,
            onAtualizar: (p) => setState(() => _parametros = p),
            precoEstimado: _precoEstimado,
            duracaoMinutos: _tipoSelecionado != null
                ? DuracaoServico.calcularMinutos(_tipoSelecionado!, _parametros)
                : null,
          ),
        2 => _EtapaEndereco(controller: _enderecoController),
        3 => _EtapaDataHora(
            dataHora: _dataHora,
            diaristId: widget.diaristIdInicial,
            duracaoMinutos: _duracaoMinutos,
            onSelecionar: (d) => setState(() => _dataHora = d),
          ),
        4 => _EtapaDescricao(
            descricaoController: _descricaoController,
            observacoesController: _observacoesController,
            tipoSelecionado: _tipoSelecionado?.value,
            endereco: _enderecoController.text,
            dataHora: _dataHora,
            precoEstimado: _precoEstimado,
          ),
        _ => const SizedBox(),
      };

  /// Inicializa parâmetros padrão ao selecionar um serviço.
  static Map<String, dynamic> _defaultParams(TipoServico tipo) =>
      switch (tipo) {
        TipoServico.limpezaResidencial => {
            'qtd_quartos': 1,
            'qtd_banheiros': 1,
            'qtd_salas': 1,
            'qtd_cozinhas': 1,
            'quantidadeComodos': 4,
          },
        TipoServico.passarRoupas => {'quantidadePecas': 1},
        TipoServico.lavarEPassar => {'quantidadePecas': 1},
        _ => {},
      };
}

// ─── Etapa 1: Tipo de Servico ─────────────────────────────────────────────────

class _EtapaTipo extends StatelessWidget {
  final TipoServico? tipoSelecionado;
  final void Function(TipoServico) onSelecionar;

  const _EtapaTipo({required this.tipoSelecionado, required this.onSelecionar});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text(
          'Que tipo de serviço?',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        const Text(
          'Selecione o serviço que você precisa',
          style: TextStyle(color: AppTheme.colorSubtext, fontSize: 15),
        ),
        const SizedBox(height: 24),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: ServicoRegistry.all.map((config) {
            final selecionado = tipoSelecionado == config.tipo;
            return GestureDetector(
              onTap: () => onSelecionar(config.tipo),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selecionado
                      ? AppTheme.primaryColor
                      : AppTheme.colorSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selecionado
                        ? AppTheme.primaryColor
                        : AppTheme.colorBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(config.icon,
                        color:
                            selecionado ? Colors.white : AppTheme.colorSubtext,
                        size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            config.label,
                            style: TextStyle(
                              color: selecionado
                                  ? Colors.white
                                  : AppTheme.colorText,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            config.unidade.label,
                            style: TextStyle(
                              color: selecionado
                                  ? Colors.white70
                                  : AppTheme.colorSubtext,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ─── Etapa 2: Parâmetros do Serviço ──────────────────────────────────────────

class _EtapaParametros extends StatelessWidget {
  final TipoServico tipo;
  final Map<String, dynamic> parametros;
  final void Function(Map<String, dynamic>) onAtualizar;
  final double? precoEstimado;
  final int? duracaoMinutos;

  const _EtapaParametros({
    required this.tipo,
    required this.parametros,
    required this.onAtualizar,
    this.precoEstimado,
    this.duracaoMinutos,
  });

  void _set(String key, dynamic value) {
    onAtualizar({...parametros, key: value});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          ServicoRegistry.get(tipo).label,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        const Text(
          'Preencha os detalhes do serviço',
          style: TextStyle(color: AppTheme.colorSubtext, fontSize: 15),
        ),
        const SizedBox(height: 24),
        ...switch (tipo) {
          TipoServico.limpezaResidencial => _buildLimpezaResidencial(),
          TipoServico.limpezaComercial => _buildLimpezaComercial(),
          TipoServico.lavarRoupas => _buildLavarRoupas(),
          TipoServico.passarRoupas => _buildPassarRoupas(),
          TipoServico.lavarEPassar => _buildLavarEPassar(),
        },
        if (duracaoMinutos != null || precoEstimado != null) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            children: [
              if (duracaoMinutos != null)
                _InfoChip(
                  icon: Icons.schedule_outlined,
                  label: 'Duração: ${DuracaoServico.formatar(duracaoMinutos!)}',
                  color: Colors.blue.shade700,
                ),
              if (precoEstimado != null)
                _InfoChip(
                  icon: Icons.attach_money,
                  label: 'Estimativa: R\$ ${precoEstimado!.toStringAsFixed(2)}',
                  color: AppTheme.successColor,
                ),
            ],
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  List<Widget> _buildLimpezaResidencial() {
    final quartos = (parametros['qtd_quartos'] as int?) ?? 1;
    final banheiros = (parametros['qtd_banheiros'] as int?) ?? 1;
    final salas = (parametros['qtd_salas'] as int?) ?? 1;
    final cozinhas = (parametros['qtd_cozinhas'] as int?) ?? 1;
    final pets = (parametros['possuiPets'] as bool?) ?? false;

    final lavanderia = (parametros['qtd_lavanderia'] as int?) ?? 0;
    final garagem = (parametros['qtd_garagem'] as int?) ?? 0;
    final gourmet = (parametros['qtd_gourmet'] as int?) ?? 0;
    final escritorio = (parametros['qtd_escritorio'] as int?) ?? 0;

    void setComodo(String key, int value) {
      final updated = {...parametros, key: value};
      // Manter quantidadeComodos como soma (compat. com validador)
      updated['quantidadeComodos'] = (updated['qtd_quartos'] as int? ?? 1) +
          (updated['qtd_banheiros'] as int? ?? 1) +
          (updated['qtd_salas'] as int? ?? 1) +
          (updated['qtd_cozinhas'] as int? ?? 1) +
          (updated['qtd_lavanderia'] as int? ?? 0) +
          (updated['qtd_garagem'] as int? ?? 0) +
          (updated['qtd_gourmet'] as int? ?? 0) +
          (updated['qtd_escritorio'] as int? ?? 0);
      onAtualizar(updated);
    }

    return [
      const _ParamLabel(label: 'Quartos', obrigatorio: true),
      const SizedBox(height: 8),
      _StepperInput(
          value: quartos,
          min: 1,
          max: 10,
          onChanged: (v) => setComodo('qtd_quartos', v)),
      const SizedBox(height: 16),
      const _ParamLabel(label: 'Banheiros', obrigatorio: true),
      const SizedBox(height: 8),
      _StepperInput(
          value: banheiros,
          min: 0,
          max: 6,
          onChanged: (v) => setComodo('qtd_banheiros', v)),
      const SizedBox(height: 16),
      const _ParamLabel(label: 'Salas', obrigatorio: true),
      const SizedBox(height: 8),
      _StepperInput(
          value: salas,
          min: 0,
          max: 5,
          onChanged: (v) => setComodo('qtd_salas', v)),
      const SizedBox(height: 16),
      const _ParamLabel(label: 'Cozinhas', obrigatorio: true),
      const SizedBox(height: 8),
      _StepperInput(
          value: cozinhas,
          min: 0,
          max: 3,
          onChanged: (v) => setComodo('qtd_cozinhas', v)),
      const SizedBox(height: 20),
      const _ParamLabel(
          label: 'Ambientes adicionais (opcional)', obrigatorio: false),
      const SizedBox(height: 16),
      const _ParamLabel(label: 'Lavanderia', obrigatorio: false),
      const SizedBox(height: 8),
      _StepperInput(
          value: lavanderia,
          min: 0,
          max: 2,
          onChanged: (v) => setComodo('qtd_lavanderia', v)),
      const SizedBox(height: 16),
      const _ParamLabel(label: 'Garagem', obrigatorio: false),
      const SizedBox(height: 8),
      _StepperInput(
          value: garagem,
          min: 0,
          max: 4,
          onChanged: (v) => setComodo('qtd_garagem', v)),
      const SizedBox(height: 16),
      const _ParamLabel(
          label: 'Área Gourmet / Churrasqueira', obrigatorio: false),
      const SizedBox(height: 8),
      _StepperInput(
          value: gourmet,
          min: 0,
          max: 2,
          onChanged: (v) => setComodo('qtd_gourmet', v)),
      const SizedBox(height: 16),
      const _ParamLabel(label: 'Escritório', obrigatorio: false),
      const SizedBox(height: 8),
      _StepperInput(
          value: escritorio,
          min: 0,
          max: 5,
          onChanged: (v) => setComodo('qtd_escritorio', v)),
      const SizedBox(height: 20),
      const _ParamLabel(label: 'Possui pets?', obrigatorio: false),
      const SizedBox(height: 8),
      _ToggleInput(
        value: pets,
        onChanged: (v) => _set('possuiPets', v),
        labelAtivo: 'Sim, tenho pets',
        labelInativo: 'Não possuo pets',
      ),
    ];
  }

  List<Widget> _buildLimpezaComercial() {
    final metragem = parametros['metragem']?.toString() ?? '';

    return [
      const _ParamLabel(label: 'Metragem do local (m²)', obrigatorio: true),
      const SizedBox(height: 8),
      TextFormField(
        initialValue: metragem,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          hintText: 'Ex: 150',
          suffixText: 'm²',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          filled: true,
          fillColor: AppTheme.colorSurface,
        ),
        onChanged: (v) {
          final parsed = double.tryParse(v.replaceAll(',', '.'));
          if (parsed != null) _set('metragem', parsed);
        },
      ),
    ];
  }

  List<Widget> _buildLavarRoupas() {
    final tamanho = parametros['tamanho'] as String?;

    return [
      const _ParamLabel(label: 'Tamanho do lote', obrigatorio: true),
      const SizedBox(height: 8),
      _OptionSelector<String>(
        options: const [
          ('Pequeno', 'pequeno'),
          ('Médio', 'medio'),
          ('Grande', 'grande'),
        ],
        selected: tamanho,
        onSelect: (v) => _set('tamanho', v),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.colorSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.colorBorder),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(texto: 'Pequeno — até 5 kg'),
            _InfoRow(texto: 'Médio — até 10 kg'),
            _InfoRow(texto: 'Grande — acima de 10 kg'),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildPassarRoupas() {
    final pecas = (parametros['quantidadePecas'] as int?) ?? 1;

    return [
      const _ParamLabel(label: 'Quantidade de peças', obrigatorio: true),
      const SizedBox(height: 8),
      _StepperInput(
        value: pecas,
        min: 1,
        max: 200,
        step: 5,
        onChanged: (v) => _set('quantidadePecas', v),
      ),
    ];
  }

  List<Widget> _buildLavarEPassar() {
    final tamanho = parametros['tamanho'] as String?;
    final pecas = (parametros['quantidadePecas'] as int?) ?? 1;

    return [
      const _ParamLabel(label: 'Tamanho do lote de roupas', obrigatorio: true),
      const SizedBox(height: 8),
      _OptionSelector<String>(
        options: const [
          ('Pequeno', 'pequeno'),
          ('Médio', 'medio'),
          ('Grande', 'grande'),
        ],
        selected: tamanho,
        onSelect: (v) => _set('tamanho', v),
      ),
      const SizedBox(height: 20),
      const _ParamLabel(
          label: 'Peças para passar (opcional)', obrigatorio: false),
      const SizedBox(height: 8),
      _StepperInput(
        value: pecas,
        min: 0,
        max: 200,
        step: 5,
        onChanged: (v) => _set('quantidadePecas', v),
      ),
    ];
  }
}

// ─── Componentes Internos de Parâmetros ──────────────────────────────────────

class _ParamLabel extends StatelessWidget {
  final String label;
  final bool obrigatorio;
  const _ParamLabel({required this.label, required this.obrigatorio});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        if (obrigatorio)
          const Text(' *',
              style: TextStyle(
                  color: AppTheme.errorColor, fontWeight: FontWeight.w600)),
        if (!obrigatorio)
          const Text('  (opcional)',
              style: TextStyle(color: AppTheme.colorSubtext, fontSize: 12)),
      ],
    );
  }
}

class _StepperInput extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final int step;
  final void Function(int) onChanged;

  const _StepperInput({
    required this.value,
    required this.min,
    required this.max,
    this.step = 1,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colorSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.colorBorder),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: value > min ? () => onChanged(value - step) : null,
          ),
          Expanded(
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: value < max ? () => onChanged(value + step) : null,
          ),
        ],
      ),
    );
  }
}

class _OptionSelector<T> extends StatelessWidget {
  final List<(String, T)> options;
  final T? selected;
  final void Function(T) onSelect;

  const _OptionSelector({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((opt) {
        final (label, value) = opt;
        final ativo = selected == value;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: ativo ? AppTheme.primaryColor : AppTheme.colorSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ativo ? AppTheme.primaryColor : AppTheme.colorBorder,
                ),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ativo ? Colors.white : AppTheme.colorText,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ToggleInput extends StatelessWidget {
  final bool value;
  final void Function(bool) onChanged;
  final String labelAtivo;
  final String labelInativo;

  const _ToggleInput({
    required this.value,
    required this.onChanged,
    required this.labelAtivo,
    required this.labelInativo,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: value ? AppTheme.primaryColor : AppTheme.colorSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value ? AppTheme.primaryColor : AppTheme.colorBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(
              value ? Icons.pets : Icons.pets_outlined,
              color: value ? Colors.white : AppTheme.colorSubtext,
            ),
            const SizedBox(width: 12),
            Text(
              value ? labelAtivo : labelInativo,
              style: TextStyle(
                color: value ? Colors.white : AppTheme.colorText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String texto;
  const _InfoRow({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 6, color: AppTheme.colorSubtext),
          const SizedBox(width: 8),
          Text(texto,
              style:
                  const TextStyle(fontSize: 13, color: AppTheme.colorSubtext)),
        ],
      ),
    );
  }
}

// ─── Etapa 3: Endereco ────────────────────────────────────────────────────────

class _EtapaEndereco extends StatefulWidget {
  final TextEditingController controller;

  const _EtapaEndereco({required this.controller});

  @override
  State<_EtapaEndereco> createState() => _EtapaEnderecoState();
}

class _EtapaEnderecoState extends State<_EtapaEndereco> {
  final _enderecoService = EnderecoService();
  List<EnderecoCliente> _enderecos = [];
  bool _carregando = true;
  String? _idSelecionado;
  bool _digitarManualmente = false;

  @override
  void initState() {
    super.initState();
    _carregarEnderecos();
  }

  Future<void> _carregarEnderecos() async {
    final userId = context.read<AuthService>().currentUserId;
    if (userId == null) {
      setState(() => _carregando = false);
      return;
    }
    try {
      final lista = await _enderecoService.getEnderecos(userId);
      if (!mounted) return;
      setState(() {
        _enderecos = lista;
        _carregando = false;
        // Pré-seleciona o endereço principal (se já não foi preenchido)
        if (widget.controller.text.isEmpty) {
          final principal = lista.where((e) => e.principal).firstOrNull;
          if (principal != null) {
            _idSelecionado = principal.id;
            widget.controller.text = principal.enderecoCompleto;
          }
        }
      });
    } catch (_) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _selecionarEndereco(EnderecoCliente e) {
    setState(() {
      _idSelecionado = e.id;
      _digitarManualmente = false;
    });
    widget.controller.text = e.enderecoCompleto;
  }

  void _ativarDigitacaoManual() {
    setState(() {
      _idSelecionado = null;
      _digitarManualmente = true;
      widget.controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text(
          'Qual o endereço?',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        const Text(
          'Selecione um endereço salvo ou digite um novo',
          style: TextStyle(color: AppTheme.colorSubtext, fontSize: 15),
        ),
        const SizedBox(height: 24),
        if (_carregando)
          const Center(child: CircularProgressIndicator())
        else ...[
          // ── Endereços salvos ──────────────────────────────────────────
          if (_enderecos.isNotEmpty) ...[
            const Text(
              'Endereços salvos',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 12),
            ..._enderecos.map((e) {
              final selecionado = _idSelecionado == e.id;
              return GestureDetector(
                onTap: () => _selecionarEndereco(e),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: selecionado
                        ? AppTheme.primaryColor.withAlpha(18)
                        : AppTheme.colorSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selecionado
                          ? AppTheme.primaryColor
                          : AppTheme.colorBorder,
                      width: selecionado ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        e.principal
                            ? Icons.home_rounded
                            : Icons.location_on_outlined,
                        color: selecionado
                            ? AppTheme.primaryColor
                            : AppTheme.colorSubtext,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  e.apelido,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: selecionado
                                        ? AppTheme.primaryColor
                                        : AppTheme.colorText,
                                  ),
                                ),
                                if (e.principal) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color:
                                          AppTheme.primaryColor.withAlpha(20),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'Principal',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${e.logradouro}, ${e.numero} — ${e.bairro}, ${e.cidade}',
                              style: const TextStyle(
                                  color: AppTheme.colorSubtext, fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (selecionado)
                        Icon(Icons.check_circle_rounded,
                            color: AppTheme.primaryColor, size: 20),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],

          // ── Opção de digitar manualmente ──────────────────────────────
          GestureDetector(
            onTap: _ativarDigitacaoManual,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _digitarManualmente
                    ? AppTheme.accentBlue.withAlpha(14)
                    : AppTheme.colorSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _digitarManualmente
                      ? AppTheme.accentBlue
                      : AppTheme.colorBorder,
                  width: _digitarManualmente ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.edit_location_alt_outlined,
                    color: _digitarManualmente
                        ? AppTheme.accentBlue
                        : AppTheme.colorSubtext,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Digitar endereço manualmente',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: _digitarManualmente
                          ? AppTheme.accentBlue
                          : AppTheme.colorText,
                    ),
                  ),
                  const Spacer(),
                  if (_digitarManualmente)
                    Icon(Icons.check_circle_rounded,
                        color: AppTheme.accentBlue, size: 20),
                ],
              ),
            ),
          ),

          if (_digitarManualmente) ...[
            const SizedBox(height: 14),
            TextField(
              controller: widget.controller,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Ex: Rua das Flores, 123, Bairro, Cidade',
                prefixIcon: const Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: AppTheme.colorSurface,
              ),
            ),
          ],
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

// ─── Etapa 3: Data e Hora ─────────────────────────────────────────────────────

// ─── Etapa 3: Data e Hora ─────────────────────────────────────────────────────
//
// Quando diaristId + duracaoMinutos estão disponíveis, exibe uma grade de
// horários válidos gerados dinamicamente (sem overbooking).
// Caso contrário, mantém o comportamento de seletor livre.

class _EtapaDataHora extends StatefulWidget {
  final DateTime? dataHora;
  final void Function(DateTime) onSelecionar;
  final String? diaristId;
  final int? duracaoMinutos;

  const _EtapaDataHora({
    required this.dataHora,
    required this.onSelecionar,
    this.diaristId,
    this.duracaoMinutos,
  });

  @override
  State<_EtapaDataHora> createState() => _EtapaDataHoraState();
}

class _EtapaDataHoraState extends State<_EtapaDataHora> {
  final _agendaService = AgendaService();
  DateTime? _dataSelecionada;
  List<TimeOfDay>? _slots;
  bool _loadingSlots = false;

  @override
  void initState() {
    super.initState();
    if (widget.dataHora != null) {
      _dataSelecionada = DateTime(
        widget.dataHora!.year,
        widget.dataHora!.month,
        widget.dataHora!.day,
      );
    }
  }

  bool get _modoInteligente =>
      widget.diaristId != null && widget.duracaoMinutos != null;

  Future<void> _selecionarData(BuildContext context) async {
    final now = DateTime.now();
    final data = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (data == null) return;

    setState(() {
      _dataSelecionada = data;
      _slots = null;
    });

    if (_modoInteligente && context.mounted) {
      _carregarSlots(data);
    } else if (!_modoInteligente && context.mounted) {
      // Sem diarista: abrir time picker livre
      final hora = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 8, minute: 0),
      );
      if (hora == null) return;
      widget.onSelecionar(
          DateTime(data.year, data.month, data.day, hora.hour, hora.minute));
    }
  }

  Future<void> _carregarSlots(DateTime data) async {
    setState(() => _loadingSlots = true);
    try {
      final slots = await _agendaService.getHorariosDisponiveis(
        diaristaId: widget.diaristId!,
        data: data,
        duracaoMinutos: widget.duracaoMinutos!,
      );
      if (mounted) setState(() => _slots = slots);
    } catch (_) {
      if (mounted) setState(() => _slots = []);
    } finally {
      if (mounted) setState(() => _loadingSlots = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat("EEEE, dd 'de' MMMM", 'pt_BR');
    final fmtCompleto = DateFormat("dd/MM 'às' HH:mm", 'pt_BR');
    final horaSelecionada = widget.dataHora != null
        ? TimeOfDay.fromDateTime(widget.dataHora!)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text(
          'Quando você precisa?',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          _modoInteligente
              ? 'Escolha a data e veja os horários disponíveis'
              : 'Escolha a data e horário para o serviço',
          style: const TextStyle(color: AppTheme.colorSubtext, fontSize: 15),
        ),
        const SizedBox(height: 24),

        // Botão de data
        GestureDetector(
          onTap: () => _selecionarData(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.colorSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _dataSelecionada != null
                    ? AppTheme.primaryColor
                    : AppTheme.colorBorder,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _dataSelecionada != null
                        ? AppTheme.primaryColor
                        : AppTheme.colorBorder,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.calendar_today_outlined,
                    size: 20,
                    color: _dataSelecionada != null
                        ? Colors.white
                        : AppTheme.colorSubtext,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    _dataSelecionada != null
                        ? fmt.format(_dataSelecionada!)
                        : 'Selecionar data',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: _dataSelecionada != null
                          ? AppTheme.colorText
                          : AppTheme.colorSubtext,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.colorSubtext),
              ],
            ),
          ),
        ),

        // Slots de horário (apenas modo inteligente)
        if (_modoInteligente && _dataSelecionada != null) ...[
          const SizedBox(height: 20),
          if (_loadingSlots)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_slots != null && _slots!.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_outlined,
                      color: Colors.orange.shade700),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Sem horários disponíveis nesta data. Tente outro dia.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            )
          else if (_slots != null && _slots!.isNotEmpty) ...[
            const Text(
              'Horários disponíveis',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            if (widget.duracaoMinutos != null) ...[
              const SizedBox(height: 4),
              Text(
                'Duração estimada: ${DuracaoServico.formatar(widget.duracaoMinutos!)}',
                style:
                    const TextStyle(color: AppTheme.colorSubtext, fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _slots!.map((slot) {
                final slotStr =
                    '${slot.hour.toString().padLeft(2, '0')}:${slot.minute.toString().padLeft(2, '0')}';
                final selecionado = horaSelecionada != null &&
                    horaSelecionada.hour == slot.hour &&
                    horaSelecionada.minute == slot.minute;
                return GestureDetector(
                  onTap: () => widget.onSelecionar(DateTime(
                    _dataSelecionada!.year,
                    _dataSelecionada!.month,
                    _dataSelecionada!.day,
                    slot.hour,
                    slot.minute,
                  )),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: selecionado
                          ? AppTheme.primaryColor
                          : AppTheme.colorSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selecionado
                            ? AppTheme.primaryColor
                            : AppTheme.colorBorder,
                      ),
                    ),
                    child: Text(
                      slotStr,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: selecionado ? Colors.white : AppTheme.colorText,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],

        // Resumo quando selecionado
        if (widget.dataHora != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    color: AppTheme.successColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  fmtCompleto.format(widget.dataHora!),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

// ─── Etapa 4: Descricao + Resumo ──────────────────────────────────────────────

class _EtapaDescricao extends StatelessWidget {
  final TextEditingController descricaoController;
  final TextEditingController observacoesController;
  final String? tipoSelecionado;
  final String endereco;
  final DateTime? dataHora;
  final double? precoEstimado;

  const _EtapaDescricao({
    required this.descricaoController,
    required this.observacoesController,
    required this.tipoSelecionado,
    required this.endereco,
    required this.dataHora,
    this.precoEstimado,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat("dd/MM 'as' HH:mm");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text(
          'Detalhes do servico',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        const Text(
          'Descreva o que voce precisa',
          style: TextStyle(color: AppTheme.colorSubtext, fontSize: 15),
        ),
        const SizedBox(height: 24),

        // Resumo rapido
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.colorSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.colorBorder),
          ),
          child: Column(
            children: [
              _ResumoLinha(
                  icon: Icons.cleaning_services_outlined,
                  texto: tipoSelecionado ?? '-'),
              const Divider(height: 12),
              _ResumoLinha(
                  icon: Icons.location_on_outlined,
                  texto: endereco.isEmpty ? '-' : endereco),
              if (dataHora != null) ...[
                const Divider(height: 12),
                _ResumoLinha(
                    icon: Icons.schedule_outlined,
                    texto: fmt.format(dataHora!)),
              ],
              if (precoEstimado != null) ...[
                const Divider(height: 12),
                _ResumoLinha(
                  icon: Icons.attach_money,
                  texto: 'Estimativa: R\$ ${precoEstimado!.toStringAsFixed(2)}',
                  cor: AppTheme.successColor,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        TextField(
          controller: descricaoController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText:
                'Descreva o que precisa ser feito (tamanho, comodos, etc.)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            filled: true,
            fillColor: AppTheme.colorSurface,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: observacoesController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Observacoes adicionais (opcional)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            filled: true,
            fillColor: AppTheme.colorSurface,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _ResumoLinha extends StatelessWidget {
  final IconData icon;
  final String texto;
  final Color? cor;

  const _ResumoLinha({required this.icon, required this.texto, this.cor});

  @override
  Widget build(BuildContext context) {
    final iconColor = cor ?? AppTheme.colorSubtext;
    final textStyle = cor != null
        ? TextStyle(fontSize: 14, color: cor, fontWeight: FontWeight.w600)
        : const TextStyle(fontSize: 14);
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            texto,
            style: textStyle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─── Chip informativo ────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
