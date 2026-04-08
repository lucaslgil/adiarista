import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
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
  String? _tipoSelecionado;
  final _enderecoController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _observacoesController = TextEditingController();
  DateTime? _dataHora;
  double? _precoEstimado;

  static const _tipos = [
    ('Casa', Icons.home_outlined, 'casa'),
    ('Apartamento', Icons.apartment_outlined, 'apartamento'),
    ('Comercial', Icons.business_outlined, 'comercial'),
    ('Faxina', Icons.cleaning_services_outlined, 'faxina'),
    ('Pos-obra', Icons.construction_outlined, 'pos_obra'),
    ('Jardim', Icons.grass_outlined, 'jardim'),
  ];

  @override
  void initState() {
    super.initState();
    _tipoSelecionado = widget.tipoInicial;
    if (_tipoSelecionado != null) _etapa = 1;
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
        1 => _enderecoController.text.trim().isNotEmpty,
        2 => _dataHora != null,
        3 => _descricaoController.text.trim().isNotEmpty,
        _ => false,
      };

  void _avancar() {
    if (_etapa < 4) {
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
        tipoLimpeza: _tipoSelecionado,
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
                  children: List.generate(4, (i) {
                    final ativo = i <= _etapa;
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
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
                  ? (_etapa == 3 ? _confirmar : _avancar)
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
                  : Text(_etapa == 3 ? 'Confirmar pedido' : 'Continuar'),
            ),
          ),
        ],
      ),
    );
  }

  String _rotuloPasso(int etapa) => switch (etapa) {
        0 => 'Passo 1 de 4 - Tipo de servico',
        1 => 'Passo 2 de 4 - Endereco',
        2 => 'Passo 3 de 4 - Data e hora',
        3 => 'Passo 4 de 4 - Descricao',
        _ => 'Confirmacao',
      };

  Widget _buildEtapa() => switch (_etapa) {
        0 => _EtapaTipo(
            tipoSelecionado: _tipoSelecionado,
            tipos: _tipos,
            onSelecionar: (t) => setState(() => _tipoSelecionado = t),
          ),
        1 => _EtapaEndereco(controller: _enderecoController),
        2 => _EtapaDataHora(
            dataHora: _dataHora,
            onSelecionar: (d) => setState(() => _dataHora = d),
          ),
        3 => _EtapaDescricao(
            descricaoController: _descricaoController,
            observacoesController: _observacoesController,
            tipoSelecionado: _tipoSelecionado,
            endereco: _enderecoController.text,
            dataHora: _dataHora,
          ),
        _ => const SizedBox(),
      };
}

// ─── Etapa 1: Tipo de Servico ─────────────────────────────────────────────────

class _EtapaTipo extends StatelessWidget {
  final String? tipoSelecionado;
  final List<(String, IconData, String)> tipos;
  final void Function(String) onSelecionar;

  const _EtapaTipo({
    required this.tipoSelecionado,
    required this.tipos,
    required this.onSelecionar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text(
          'Que tipo de servico?',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        const Text(
          'Selecione o tipo de limpeza que voce precisa',
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
          children: tipos.map((t) {
            final (label, icon, value) = t;
            final selecionado = tipoSelecionado == value;
            return GestureDetector(
              onTap: () => onSelecionar(value),
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
                    Icon(icon,
                        color:
                            selecionado ? Colors.white : AppTheme.colorSubtext,
                        size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: selecionado
                              ? Colors.white
                              : AppTheme.colorText,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
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

// ─── Etapa 2: Endereco ────────────────────────────────────────────────────────

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
