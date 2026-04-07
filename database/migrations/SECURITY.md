# 🔒 Guia de Segurança - aDiarista

## ⚠️ Informações Sensíveis

### ✅ O QUE PODE SER EXPOSTO:
- **Supabase Anon Key**: É pública e segura para frontend
  - Protegida por Row Level Security (RLS)
  - Localização: `mobile/lib/config/supabase_config.dart`
  
- **Supabase URL**: Público e necessário para conexão

### ❌ O QUE NUNCA DEVE SER EXPOSTO:
- **Supabase Service Key**: Acesso total ao banco
- **Chaves de API de pagamento** (quando implementar)
- **Secrets de webhooks**
- **Tokens de autenticação de terceiros**

## 🛡️ Proteções Implementadas

### 1. Row Level Security (RLS)
Todas as tabelas têm políticas RLS ativas:
- `users`: Todos veem perfis públicos, só editam o próprio
- `clientes`: Só veem o próprio perfil
- `diaristas`: Todos veem diaristas ativas, só editam o próprio
- `solicitacoes`: Filtradas por status e ownership
- `avaliacoes`: Todos veem, apenas clientes criam

### 2. Git Ignore
O arquivo `.gitignore` protege:
- Arquivos `.env` (variáveis de ambiente)
- Configurações locais (IDE, build, cache)
- Credentials e tokens

### 3. Validação de Input
- Email: Regex validation
- CPF: Formato brasileiro
- Telefone: 10-11 dígitos
- Todas as entradas sanitizadas

## 📝 Checklist de Segurança

### Antes do Deploy
- [ ] Revisar todas as políticas RLS no Supabase
- [ ] Confirmar que `.env` está no `.gitignore`
- [ ] Remover console.log() com dados sensíveis
- [ ] Testar autenticação e autorização
- [ ] Verificar HTTPS em todas as conexões
- [ ] Configurar rate limiting no Supabase (plano pago)

### Em Produção
- [ ] Habilitar backup automático do Supabase
- [ ] Configurar alertas de segurança
- [ ] Implementar logging de ações críticas
- [ ] Revisar logs regularmente
- [ ] Manter dependências atualizadas
- [ ] Implementar 2FA para admin (futuro)

## 🔐 Boas Práticas Recomendadas

### Para Desenvolvimento:
1. **Nunca commite credenciais**
   ```bash
   # Use .env.example como template
   cp .env.example .env
   # Preencha com valores reais
   ```

2. **Use diferentes projetos Supabase**
   - Development: Testes e desenvolvimento
   - Staging: Homologação
   - Production: Ambiente real

3. **Rotacione chaves periodicamente**
   - Service keys a cada 3-6 meses
   - API keys de terceiros conforme política

### Para Produção:
1. **Habilite HTTPS obrigatório**
2. **Configure CORS adequadamente** no Supabase
3. **Implemente rate limiting** para APIs
4. **Use Supabase Edge Functions** para lógica sensível
5. **Monitore tentativas de acesso suspeitas**

## 📞 Resposta a Incidentes

Se você suspeitar de exposição de credenciais:

1. **Imediatamente**:
   - Rotacione a chave exposta no Supabase
   - Revise logs de acesso
   - Notifique a equipe

2. **Dentro de 24h**:
   - Audite todas as operações recentes
   - Verifique integridade dos dados
   - Documente o incidente

3. **Prevenção futura**:
   - Analise como a exposição ocorreu
   - Implemente proteções adicionais
   - Treine equipe sobre segurança

## 🔗 Recursos

- [Supabase Security Best Practices](https://supabase.com/docs/guides/platform/security)
- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)
- [Flutter Security](https://docs.flutter.dev/security)

---

**Última atualização**: Abril 2026  
**Responsável**: Equipe aDiarista
