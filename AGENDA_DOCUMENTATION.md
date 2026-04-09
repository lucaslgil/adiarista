-- ========================================================================
-- DOCUMENTAÇÃO: SISTEMA DE AGENDA PARA DIARISTAS
-- ========================================================================

## 📋 COMO FUNCIONA

### FLUXO SIMPLES:

1️⃣ DIARISTA LIBERA UM DIA
   └─ Status: "meio_periodo" ou "integral"
   └─ Horários: 07:00 - 13:00 (exemplo)

2️⃣ CLIENTE CONTRATA
   └─ Tipo: Meio Período (4h) ou Integral (8h)
   └─ Sistema automaticamente valida compatibilidade

3️⃣ VALIDAÇÕES AUTOMÁTICAS
   └─ Se INTEGRAL: bloqueia o dia todo
   └─ Se MEIO_PERÍODO: permite até 2 no mesmo dia


## 🎯 EXEMPLOS PRÁTICOS

### EXEMPLO 1: Duas casas no mesmo dia (2× Meio Período)

┌─────────────────────────────────────────────────────────────┐
│ SEGUNDA-FEIRA, 10/04/2026                                   │
│ Status: Meio Período | Horários: 07h-13h                    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  SLOT 1: 07:00 - 10:00                                       │
│  ✅ AGENDADO: "Casa da Maria" (Meio Período)                │
│                                                              │
│  INTERVALO: 10:00 - 10:30 (deslocamento)                   │
│                                                              │
│  SLOT 2: 10:30 - 13:00                                       │
│  ✅ AGENDADO: "Apt Sr. João" (Meio Período)                 │
│                                                              │
└─────────────────────────────────────────────────────────────┘

### EXEMPLO 2: Um cliente o dia todo (Integral)

┌─────────────────────────────────────────────────────────────┐
│ TERÇA-FEIRA, 11/04/2026                                      │
│ Status: Integral | Horários: 07h-18h                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  SLOT ÚNICO: 07:00 - 18:00                                   │
│  ✅ AGENDADO: "Limpeza Residência grandes" (Integral)      │
│                                                              │
│  [Dia completamente ocupado]                                │
│                                                              │
└─────────────────────────────────────────────────────────────┘

### EXEMPLO 3: Dia bloqueado

┌─────────────────────────────────────────────────────────────┐
│ QUARTA-FEIRA, 12/04/2026                                     │
│ Status: BLOQUEADO                                            │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  🚫 DESCANSO / INDISPONÍVEL                                 │
│  (Nenhum agendamento é aceito)                              │
│                                                              │
└─────────────────────────────────────────────────────────────┘


## 🗂️ ESTRUTURA DE ARQUIVOS CRIADOS

.
├── database/migrations/
│   └── 005_agenda_diarista.sql          (💾 Banco de dados)
│
└── mobile/lib/
    ├── models/
    │   ├── configuracao_agenda.dart       (⚙️ Configuração padrão)
    │   ├── diarista_disponibilidade.dart  (📅 Status da disponibilidade)
    │   └── agendamento_diarista.dart      (📌 Agendamentos realizados)
    │
    └── services/
        └── agenda_validation_service.dart (✅ Lógica de validação)


## 📊 TABELAS DO BANCO

### configuracao_agenda
- id: Identificador
- diarista_id: ID da diarista
- hora_inicio_padrao: 08:00
- hora_fim_padrao: 18:00
- tempo_deslocamento_minutos: 30

### diarista_disponibilidade
- id: Identificador
- diarista_id: ID da diarista
- data: 2026-04-10
- status: 'bloqueado' | 'meio_periodo' | 'integral'
- hora_inicio: 07:00 (override opcional)
- hora_fim: 13:00 (override opcional)

### agendamentos_diarista
- id: Identificador
- diarista_id: ID da diarista
- cliente_id: ID do cliente
- data_agendamento: 2026-04-10
- horario_inicio: 08:00
- horario_fim: 12:00
- tipo_servico: 'meio_periodo' | 'integral'
- status: 'pendente' | 'confirmado' | 'em_progresso' | 'finalizado'
- endereco: Endereço do cliente
- valor_acordado: R$ 150,00


## 🔐 REGRAS DE NEGÓCIO

### Validação de Agendamento

✅ PODE AGENDAR se:
  1. Dia não está bloqueado
  2. INTEGRAL: não há nenhum agendamento confirmado
  3. MEIO_PERÍODO: há menos de 2 agendamentos confirmados
  4. Não há sobreposição de horários (considerando deslocamento)
  5. Horário está dentro da disponibilidade

❌ NÃO PODE AGENDAR se:
  1. Dia está bloqueado (status = 'bloqueado')
  2. INTEGRAL: já há agendamento confirmado
  3. MEIO_PERÍODO: já há 2 agendamentos confirmados
  4. Horários se sobrepõem (com margem de deslocamento)
  5. Sair de fora do horário de trabalho


## 💻 COMO USAR NO CÓDIGO

### 1. Validar antes de agendar

```dart
final resultado = AgendaValidationService.validarAgendamento(
  data: DateTime(2026, 4, 10),
  tipoServico: TipoServico.meioPeríodo,
  inicio: TimeOfDay(hour: 8, minute: 0),
  fim: TimeOfDay(hour: 12, minute: 0),
  agendamentosExistentes: agendamentos,
  disponibilidade: disponibilidade,
  tempoDeslocamentoMinutos: 30,
);

if (resultado.valido) {
  print('✅ ${resultado.mensagem}');
} else {
  print('❌ ${resultado.mensagem}');
}
```

### 2. Recomender tipos disponíveis

```dart
final tipos = AgendaValidationService.recomendarTipos(
  agendamentosExistentes: agendamentos,
  data: DateTime(2026, 4, 10),
);

// Se retorna [TipoServico.meioPeríodo, TipoServico.integral]
//   → Pode contratar ambos
// Se retorna [TipoServico.meioPeríodo]
//   → Pode contratar só meio período
// Se retorna []
//   → Dia está cheio, nada disponível
```

### 3. Buscar slots disponíveis

```dart
final slots = AgendaValidationService.obterSlotsDisponiveis(
  data: DateTime(2026, 4, 10),
  inicio: TimeOfDay(hour: 7, minute: 0),
  fim: TimeOfDay(hour: 13, minute: 0),
  agendamentosExistentes: agendamentos,
);

// Retorna lista de SlotDisponivel com horários
```


## 🎨 PRÓXIMOS PASSOS (UI/UX)

1. Criar Widget de Calendário (semanal/mensal)
2. Criar Tela de Gerenciamento de Disponibilidade
3. Criar Tela de Agendamentos
4. Integrar com Supabase (fetch/insert)
5. Adicionar notificações

========================================================================
