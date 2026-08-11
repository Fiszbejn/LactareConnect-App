# 🌱 LactareConnect

App mobile que conecta **pessoas doadoras de leite humano** a bancos de leite, tornando o processo de doação mais simples, transparente e acolhedor — do primeiro cadastro ao agendamento da coleta.

Projeto acadêmico (FIAP) desenvolvido em Flutter, com backend próprio em NestJS e assistente virtual (Lila) com IA generativa integrada.

---

## 📱 Sobre o projeto

Doar leite humano depende de burocracia que muitas vezes afasta quem quer ajudar: dúvidas sobre exames exigidos, dificuldade de achar um banco de leite próximo, falta de acompanhamento do processo. O LactareConnect existe para reduzir essa fricção, oferecendo em um único app:

- Localização de bancos de leite próximos, com mapa real;
- Checklist guiado dos exames pré-doação exigidos;
- Agendamento da coleta e acompanhamento do status;
- Um sistema de recompensas ("Gotinhas") que reconhece cada doação;
- Uma assistente virtual (Lila) para tirar dúvidas a qualquer momento.

O tom de voz e o vocabulário do app (ex: "leite humano" em vez de "leite materno", "pessoa doadora" em vez de reduzir a identidade a "mãe") seguem um manual de marca próprio, com o cuidado de nunca pressionar ou culpar quem está decidindo, pausando ou parando de doar.

## ✨ Funcionalidades

| Aba | O que faz |
|---|---|
| **Início / FAQ** | Perguntas frequentes categorizadas, com busca e feedback de utilidade |
| **Doar** | Mapa de bancos de leite (OpenStreetMap), geolocalização, upload de exames, agendamento da coleta |
| **Chat (Lila)** | Assistente virtual com IA generativa (Google Gemini), com contexto da FAQ real do app |
| **Recompensas** | Catálogo de recompensas resgatáveis com o saldo de Gotinhas acumulado a cada doação |
| **Conta** | Perfil, edição de dados/endereço, preferências de notificação e logout |

Todo o fluxo — cadastro, login, agendamento, upload de exame, resgate de recompensa, conversa com a Lila — é validado ponta a ponta contra o backend real, não apenas mockado.

## 🏗️ Arquitetura e stack

**App (este repositório)**
- **Flutter** (Dart) — Android, iOS e Web
- **Riverpod** para gerenciamento de estado (`AsyncNotifier`/`FutureProvider`)
- **go_router** para navegação declarativa, com guard de sessão/RBAC
- **Dio** como cliente HTTP, com interceptors para token Bearer e tratamento de erros
- **flutter_secure_storage** para persistência segura do JWT
- **flutter_map + geolocator** para mapa real e geolocalização na tela de doação
- **image_picker + file_picker** para upload de exames
- Organização **feature-first** inspirada em Clean Architecture, com camadas `domain` / `data` / `presentation` por feature — pragmática o suficiente para não gerar abstração desnecessária em telas simples

**Backend** ([`LactareConnect-backend`](https://github.com/Fiszbejn/LactareConnect-backend))
- **NestJS** (TypeScript) com **TypeORM** sobre **Oracle Database**
- Autenticação **JWT** + autorização **RBAC** (papéis `nutriz`/`administrador`, incluindo regra "dono do próprio registro")
- API REST documentada via **Swagger**, containerizada com **Docker Compose**
- Assistente virtual **Lila** integrada ao **Google Gemini** (`@google/genai`), com prompt de sistema construído dinamicamente a partir da FAQ cadastrada e do tom de marca do produto

```
lib/
├── core/                 # Infra compartilhada: tema, rede (Dio), sessão, rotas, widgets
│   ├── error/
│   ├── network/
│   ├── router/
│   ├── session/
│   ├── theme/
│   └── widgets/
└── features/             # Uma pasta por funcionalidade, mesma estrutura interna
    ├── auth/
    ├── faq/
    ├── doacao/
    ├── chat/
    ├── recompensas/
    └── conta/
        ├── data/         # Repositórios, DTOs, chamadas HTTP
        ├── domain/       # Entidades e regras de negócio
        └── presentation/ # Telas, controllers/providers Riverpod
```

## 🚀 Como rodar

### Pré-requisitos
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (^3.11.3)
- [Docker](https://www.docker.com/) (para o backend)
- Um emulador Android/iOS, Chrome, ou dispositivo físico

### 1. Backend
```bash
git clone https://github.com/Fiszbejn/LactareConnect-backend.git
cd LactareConnect-backend
cp .env.example .env   # preencher credenciais do Oracle, JWT_SECRET e GEMINI_API_KEY
docker compose up --build -d
```
A API sobe em `http://localhost:3000`, com documentação Swagger em `/docs`.

### 2. App
```bash
flutter pub get
flutter run                # escolhe o dispositivo disponível
# ou, por exemplo:
flutter run -d chrome
flutter run -d emulator-5554
```

## 🧠 Destaques técnicos

- **Integração com IA generativa**: a Lila usa o histórico real da conversa + a base de FAQ do produto como contexto para o Gemini, com fallback gracioso caso a API externa falhe (o endpoint nunca quebra).
- **RBAC granular por método HTTP**: o backend libera `POST` para a nutriz apenas nos próprios registros e mantém `GET` (histórico de conversas) restrito a administradores — uma decisão de produto (privacidade da conversa) garantida estruturalmente na API, não só na camada visual do app.
- **Escopo sempre validado contra o contrato real da API**: funcionalidades do wireframe original sem respaldo real no backend (ex: regras de pontuação fictícias, campos inexistentes) foram conscientemente cortadas ou ajustadas, em vez de mockadas — o que se vê no app é o que o backend de fato suporta.
- **Tratamento de casos de borda reais**: geolocalização sem sinal de GPS, contas sem endereço cadastrado, timestamps em UTC vindos do backend, navegação aninhada com `go_router` — todos identificados testando o app de ponta a ponta, não só por análise estática.

## 🗺️ Roadmap

- [x] App da pessoa doadora completo (5 abas + assistente com IA real)
- [ ] Webapp administrativo (consumindo o mesmo backend NestJS)
- [ ] Integração da Lila com WhatsApp + lembretes periódicos de doação

## 👤 Autor

Desenvolvido por [Fiszbejn](https://github.com/Fiszbejn).
