import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/endereco_cliente.dart';
import '../../services/auth_service.dart';
import '../../services/endereco_service.dart';

/// Tela completa de gerenciamento de endereços do cliente.
/// Pode ser usada como tela standalone ou como aba no home.
class MeusEnderecosScreen extends StatefulWidget {
  /// Se true, exibe AppBar com back button (modo standalone/rota).
  /// Se false, integra como aba no IndexedStack do home.
  final bool standalone;

  const MeusEnderecosScreen({Key? key, this.standalone = false})
      : super(key: key);

  @override
  State<MeusEnderecosScreen> createState() => _MeusEnderecosScreenState();
}

class _MeusEnderecosScreenState extends State<MeusEnderecosScreen> {
  final _enderecoService = EnderecoService();
  List<EnderecoCliente> _enderecos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final userId = context.read<AuthService>().currentUserId;
    if (userId == null) return;
    setState(() => _isLoading = true);
    try {
      final lista = await _enderecoService.getEnderecos(userId);
      if (mounted) setState(() => _enderecos = lista);
    } catch (e) {
      if (mounted) _mostrarErro('Erro ao carregar endereços: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _abrirFormulario([EnderecoCliente? edicao]) async {
    final userId = context.read<AuthService>().currentUserId;
    if (userId == null) return;

    final resultado = await showModalBottomSheet<EnderecoCliente>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioEndereco(
        clienteId: userId,
        edicao: edicao,
      ),
    );

    if (resultado != null) {
      setState(() => _isLoading = true);
      try {
        if (edicao == null) {
          await _enderecoService.criarEndereco(resultado);
        } else {
          await _enderecoService.atualizarEndereco(resultado);
        }
        await _carregar();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(edicao == null
                ? 'Endereço adicionado!'
                : 'Endereço atualizado!'),
            backgroundColor: AppTheme.successColor,
          ));
        }
      } catch (e) {
        if (mounted) _mostrarErro('$e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmarRemocao(EnderecoCliente endereco) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remover endereço'),
        content: Text(
            'Deseja remover "${endereco.apelido}"?\nEsta ação não pode ser desfeita.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    setState(() => _isLoading = true);
    try {
      await _enderecoService.removerEndereco(endereco.id);
      await _carregar();
    } catch (e) {
      if (mounted) _mostrarErro('$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _definirPrincipal(EnderecoCliente endereco) async {
    if (endereco.principal) return;
    final userId = context.read<AuthService>().currentUserId;
    if (userId == null) return;
    setState(() => _isLoading = true);
    try {
      await _enderecoService.definirPrincipal(
          enderecoId: endereco.id, clienteId: userId);
      await _carregar();
    } catch (e) {
      if (mounted) _mostrarErro('$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.errorColor,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final corpo = _buildCorpo();

    if (widget.standalone) {
      return Scaffold(
        backgroundColor: AppTheme.colorBackground,
        appBar: AppBar(
          title: const Text('Meus Endereços'),
          backgroundColor: AppTheme.colorBackground,
          elevation: 0,
        ),
        body: corpo,
        floatingActionButton: _Fab(onTap: () => _abrirFormulario()),
      );
    }

    // Modo aba — sem AppBar própria
    return Scaffold(
      backgroundColor: AppTheme.colorBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Meus Endereços'),
            floating: true,
            backgroundColor: AppTheme.colorBackground,
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _abrirFormulario(),
                tooltip: 'Adicionar endereço',
              ),
            ],
          ),
          SliverToBoxAdapter(child: corpo),
        ],
      ),
    );
  }

  Widget _buildCorpo() {
    if (_isLoading && _enderecos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_enderecos.isEmpty) {
      return _EstadoVazio(onAdicionar: () => _abrirFormulario());
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: _enderecos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _EnderecoCard(
        endereco: _enderecos[i],
        onEditar: () => _abrirFormulario(_enderecos[i]),
        onRemover: () => _confirmarRemocao(_enderecos[i]),
        onDefinirPrincipal: () => _definirPrincipal(_enderecos[i]),
      ),
    );
  }
}

// ─── FAB ─────────────────────────────────────────────────────────────────────

class _Fab extends StatelessWidget {
  final VoidCallback onTap;
  const _Fab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onTap,
      icon: const Icon(Icons.add_location_alt_outlined),
      label: const Text('Novo endereço'),
    );
  }
}

// ─── Estado vazio ─────────────────────────────────────────────────────────────

class _EstadoVazio extends StatelessWidget {
  final VoidCallback onAdicionar;
  const _EstadoVazio({required this.onAdicionar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 32),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withAlpha(18),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.location_on_outlined,
                size: 40, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 20),
          const Text(
            'Nenhum endereço cadastrado',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Adicione seus endereços para agilizar a solicitação de serviços',
            style: TextStyle(color: AppTheme.colorSubtext, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: onAdicionar,
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('Adicionar endereço'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card de endereço ─────────────────────────────────────────────────────────

class _EnderecoCard extends StatelessWidget {
  final EnderecoCliente endereco;
  final VoidCallback onEditar;
  final VoidCallback onRemover;
  final VoidCallback onDefinirPrincipal;

  const _EnderecoCard({
    required this.endereco,
    required this.onEditar,
    required this.onRemover,
    required this.onDefinirPrincipal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colorSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: endereco.principal
              ? AppTheme.primaryColor.withAlpha(120)
              : AppTheme.colorBorder,
          width: endereco.principal ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: endereco.principal
                    ? AppTheme.primaryColor.withAlpha(20)
                    : AppTheme.colorBorder.withAlpha(60),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                endereco.principal
                    ? Icons.home_rounded
                    : Icons.location_on_outlined,
                color: endereco.principal
                    ? AppTheme.primaryColor
                    : AppTheme.colorSubtext,
                size: 22,
              ),
            ),
            title: Row(
              children: [
                Text(
                  endereco.apelido,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
                if (endereco.principal) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Principal',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '${endereco.logradouro}, ${endereco.numero}'
                '${endereco.complemento != null && endereco.complemento!.isNotEmpty ? ' — ${endereco.complemento}' : ''}\n'
                '${endereco.bairro}, ${endereco.cidade} · ${endereco.cep}',
                style: const TextStyle(
                    color: AppTheme.colorSubtext, fontSize: 13, height: 1.4),
              ),
            ),
            isThreeLine: true,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                if (!endereco.principal)
                  TextButton.icon(
                    onPressed: onDefinirPrincipal,
                    icon: const Icon(Icons.star_outline, size: 16),
                    label: const Text('Definir principal'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.colorSubtext,
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                const Spacer(),
                IconButton(
                  onPressed: onEditar,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: AppTheme.accentBlue,
                  tooltip: 'Editar',
                ),
                IconButton(
                  onPressed: onRemover,
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: AppTheme.errorColor,
                  tooltip: 'Remover',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Formulário de endereço (bottomSheet) ────────────────────────────────────

class _FormularioEndereco extends StatefulWidget {
  final String clienteId;
  final EnderecoCliente? edicao;

  const _FormularioEndereco({required this.clienteId, this.edicao});

  @override
  State<_FormularioEndereco> createState() => _FormularioEnderecoState();
}

class _FormularioEnderecoState extends State<_FormularioEndereco> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _apelido;
  late final TextEditingController _logradouro;
  late final TextEditingController _numero;
  late final TextEditingController _complemento;
  late final TextEditingController _bairro;
  late final TextEditingController _cidade;
  late final TextEditingController _estado;
  late final TextEditingController _cep;
  late bool _principal;
  bool _buscandoCep = false;
  String? _erroCep;

  @override
  void initState() {
    super.initState();
    final e = widget.edicao;
    _apelido = TextEditingController(text: e?.apelido ?? '');
    _logradouro = TextEditingController(text: e?.logradouro ?? '');
    _numero = TextEditingController(text: e?.numero ?? '');
    _complemento = TextEditingController(text: e?.complemento ?? '');
    _bairro = TextEditingController(text: e?.bairro ?? '');
    _cidade = TextEditingController(text: e?.cidade ?? '');
    _estado = TextEditingController(text: e?.estado ?? '');
    _cep = TextEditingController(text: e?.cep ?? '');
    _principal = e?.principal ?? false;

    _cep.addListener(_onCepChanged);
  }

  String _apenasDigitos(String v) => v.replaceAll(RegExp(r'\D'), '');

  Future<void> _onCepChanged() async {
    final digits = _apenasDigitos(_cep.text);

    // Formata automaticamente como 00000-000
    if (digits.length <= 8) {
      String formatted = digits;
      if (digits.length > 5) {
        formatted = '${digits.substring(0, 5)}-${digits.substring(5)}';
      }
      if (formatted != _cep.text) {
        _cep.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    }

    // Busca apenas quando tiver 8 dígitos completos
    if (digits.length != 8) return;

    setState(() {
      _buscandoCep = true;
      _erroCep = null;
    });

    try {
      final uri = Uri.parse('https://viacep.com.br/ws/$digits/json/');
      final response = await http.get(uri).timeout(const Duration(seconds: 6));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data.containsKey('erro')) {
          setState(() => _erroCep = 'CEP não encontrado.');
        } else {
          _logradouro.text = data['logradouro'] as String? ?? '';
          _bairro.text = data['bairro'] as String? ?? '';
          _cidade.text = data['localidade'] as String? ?? '';
          _estado.text = data['uf'] as String? ?? '';
          // Move foco para o campo Número após preencher
          FocusScope.of(context).nextFocus();
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

  @override
  void dispose() {
    _cep.removeListener(_onCepChanged);
    _apelido.dispose();
    _logradouro.dispose();
    _numero.dispose();
    _complemento.dispose();
    _bairro.dispose();
    _cidade.dispose();
    _estado.dispose();
    _cep.dispose();
    super.dispose();
  }

  void _salvar() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final endereco = EnderecoCliente(
      id: widget.edicao?.id ?? '',
      clienteId: widget.clienteId,
      apelido: _apelido.text.trim(),
      logradouro: _logradouro.text.trim(),
      numero: _numero.text.trim(),
      complemento:
          _complemento.text.trim().isNotEmpty ? _complemento.text.trim() : null,
      bairro: _bairro.text.trim(),
      cidade: _cidade.text.trim(),
      estado: _estado.text.trim().toUpperCase(),
      cep: _cep.text.trim(),
      principal: _principal,
      criadoEm: widget.edicao?.criadoEm ?? DateTime.now(),
    );

    Navigator.pop(context, endereco);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottom + 24),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
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

              Text(
                widget.edicao == null ? 'Novo endereço' : 'Editar endereço',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),

              _Campo(
                controller: _apelido,
                label: 'Apelido',
                hint: 'Ex: Casa, Trabalho, Apartamento...',
                obrigatorio: true,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _cep,
                keyboardType: TextInputType.number,
                maxLength: 9,
                decoration: InputDecoration(
                  labelText: 'CEP',
                  hintText: '00000-000',
                  counterText: '',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: AppTheme.colorSurface,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  suffixIcon: _buscandoCep
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _erroCep == null &&
                              _apenasDigitos(_cep.text).length == 8
                          ? const Icon(Icons.check_circle_outline,
                              color: AppTheme.successColor)
                          : null,
                  errorText: _erroCep,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 14),
              _Campo(
                controller: _logradouro,
                label: 'Logradouro',
                hint: 'Rua, Avenida, Travessa...',
                obrigatorio: true,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _Campo(
                      controller: _numero,
                      label: 'Número',
                      hint: '123',
                      obrigatorio: true,
                      keyboardType: TextInputType.text,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: _Campo(
                      controller: _complemento,
                      label: 'Complemento',
                      hint: 'Apto, Bloco...',
                      obrigatorio: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _Campo(
                controller: _bairro,
                label: 'Bairro',
                hint: 'Nome do bairro',
                obrigatorio: true,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _Campo(
                      controller: _cidade,
                      label: 'Cidade',
                      hint: 'Sua cidade',
                      obrigatorio: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: _Campo(
                      controller: _estado,
                      label: 'UF',
                      hint: 'SP',
                      obrigatorio: true,
                      maxLength: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Toggle principal
              GestureDetector(
                onTap: () => setState(() => _principal = !_principal),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: _principal
                            ? AppTheme.primaryColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _principal
                              ? AppTheme.primaryColor
                              : AppTheme.colorBorder,
                          width: 2,
                        ),
                      ),
                      child: _principal
                          ? const Icon(Icons.check,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    const Text('Definir como endereço principal',
                        style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _salvar,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                child: Text(widget.edicao == null ? 'Adicionar' : 'Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obrigatorio;
  final TextInputType? keyboardType;
  final int? maxLength;

  const _Campo({
    required this.controller,
    required this.label,
    required this.hint,
    this.obrigatorio = false,
    this.keyboardType,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: AppTheme.colorSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      validator: obrigatorio
          ? (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null
          : null,
    );
  }
}
