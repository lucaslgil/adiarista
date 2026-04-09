import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/servico.dart';
import '../../services/auth_service.dart';
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
    if (_etapa < 5) {
      setState(() => _etapa++);
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
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
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
              _parametros = {};
            }),
          ),
        1 => _EtapaParametros(
            tipo: _tipoSelecionado!,
            parametros: _parametros,
            onAtualizar: (p) => setState(() => _parametros = p),
          ),
        2 => _EtapaEndereco(controller: _enderecoController),
        3 => _EtapaDataHora(
            dataHora: _dataHora,
            onSelecionar: (d) => setState(() => _dataHora = d),
          ),
        4 => _EtapaDescricao(
            descricaoController: _descricaoController,
            observacoesController: _observacoesController,
            tipoSelecionado: _tipoSelecionado?.value,
            endereco: _enderecoController.text,
            dataHora: _dataHora,
          ),
        _ => const SizedBox(),
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
                        color: selecionado
                            ? Colors.white
                            : AppTheme.colorSubtext,
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

  const _EtapaParametros({
    required this.tipo,
    required this.parametros,
    required this.onAtualizar,
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
        },
        const SizedBox(height: 24),
      ],
    );
  }

  List<Widget> _buildLimpezaResidencial() {
    final comodos = (parametros['quantidadeComodos'] as int?) ?? 1;
    final nivel = parametros['nivelSujeira'] as String?;
    final pets = (parametros['possuiPets'] as bool?) ?? false;

    return [
      const _ParamLabel(label: 'Quantidade de cômodos', obrigatorio: true),
      const SizedBox(height: 8),
      _StepperInput(
        value: comodos,
        min: 1,
        max: 20,
        onChanged: (v) => _set('quantidadeComodos', v),
      ),
      const SizedBox(height: 20),
      const _ParamLabel(label: 'Nível de sujeira', obrigatorio: true),
      const SizedBox(height: 8),
      _OptionSelector<String>(
        options: const [
          ('Leve', 'leve'),
          ('Médio', 'medio'),
          ('Pesado', 'pesado'),
        ],
        selected: nivel,
        onSelect: (v) => _set('nivelSujeira', v),
      ),
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
              style:
                  TextStyle(color: AppTheme.colorSubtext, fontSize: 12)),
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
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.colorSubtext)),
        ],
      ),
    );
  }
}

// ─── Etapa 3: Endereco ────────────────────────────────────────────────────────

class _EtapaEndereco extends StatelessWidget {
  final TextEditingController controller;

  const _EtapaEndereco({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text(
          'Qual o endereco?',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        const Text(
          'Informe onde o servico sera realizado',
          style: TextStyle(color: AppTheme.colorSubtext, fontSize: 15),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: controller,
          maxLines: 3,
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
        const SizedBox(height: 24),
      ],
    );
  }
}

// ─── Etapa 3: Data e Hora ─────────────────────────────────────────────────────

class _EtapaDataHora extends StatelessWidget {
  final DateTime? dataHora;
  final void Function(DateTime) onSelecionar;

  const _EtapaDataHora({required this.dataHora, required this.onSelecionar});

  Future<void> _selecionar(BuildContext context) async {
    final now = DateTime.now();
    final data = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (data == null || !context.mounted) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (hora == null) return;

    onSelecionar(DateTime(
        data.year, data.month, data.day, hora.hour, hora.minute));
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat("EEEE, dd 'de' MMMM 'as' HH:mm", 'pt_BR');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text(
          'Quando voce precisa?',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        const Text(
          'Escolha a data e horario para o servico',
          style: TextStyle(color: AppTheme.colorSubtext, fontSize: 15),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () => _selecionar(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.colorSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: dataHora != null
                    ? AppTheme.primaryColor
                    : AppTheme.colorBorder,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: dataHora != null
                        ? AppTheme.primaryColor
                        : AppTheme.colorBorder,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_today_outlined,
                    color: dataHora != null ? Colors.white : AppTheme.colorSubtext,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dataHora != null
                            ? fmt.format(dataHora!)
                            : 'Selecionar data e hora',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: dataHora != null
                              ? AppTheme.colorText
                              : AppTheme.colorSubtext,
                        ),
                      ),
                      if (dataHora == null)
                        const Text(
                          'Toque para escolher',
                          style: TextStyle(
                              color: AppTheme.colorSubtext, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.colorSubtext),
              ],
            ),
          ),
        ),
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

  const _EtapaDescricao({
    required this.descricaoController,
    required this.observacoesController,
    required this.tipoSelecionado,
    required this.endereco,
    required this.dataHora,
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

  const _ResumoLinha({required this.icon, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.colorSubtext),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
