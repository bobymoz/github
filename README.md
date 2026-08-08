# Suckit (app nativo Flutter, cliente da API do Flarum)

App 100% nativo que consome a API REST (JSON:API) do Flarum instalado em
https://forum.bitbrit.website. Sem WebView.

## Como subir para o GitHub

```bash
git add .
git commit -m "App nativo consumindo a API do Flarum"
git push
```

## O que tem nessa versão

- Login e cadastro (via /api/token e /api/users do Flarum)
- Lista de tópicos, com filtro por categoria (tags) no menu lateral
- Ver um tópico e suas respostas
- Responder um tópico
- Criar um tópico novo, escolhendo categorias

## O que NÃO está incluso (dá pra adicionar depois)

- Notificações
- Mensagens privadas
- Edição/exclusão de posts
- Perfil de usuário completo (avatar upload, bio)
- Moderação (trancar, fixar, mover tópicos)
- "Esqueci minha senha" (o método existe no serviço, só falta a tela)

## Importante: configurar o Flarum

- **Nome e logo do fórum:** painel admin do Flarum → Basics / Appearance
  (não é mais configurado no código do app)
- **Cor:** Appearance → Primary color → `#4D698E` (a mesma da demo)
- **Email do Flarum:** Admin → Mail → configure o SMTP do Resend (mesmas
  credenciais que já usamos antes: host `smtp.resend.com`, porta `587`,
  usuário `resend`, senha = sua API key do Resend) — sem isso, cadastro com
  confirmação de email e recuperação de senha não funcionam

## Estrutura

- `lib/services/flarum_api.dart` — cliente HTTP de baixo nível (JSON:API, token)
- `lib/services/forum_service.dart` — chamadas de alto nível (login, tópicos, posts)
- `lib/screens/auth_screen.dart` — login/cadastro
- `lib/screens/discussions_list_screen.dart` — lista de tópicos + categorias
- `lib/screens/discussion_detail_screen.dart` — tópico + respostas
- `lib/screens/create_discussion_screen.dart` — criar tópico
