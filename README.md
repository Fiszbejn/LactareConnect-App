# 🌱 LactareConnect

App mobile que conecta **pessoas doadoras de leite humano** a bancos de leite, do cadastro ao agendamento da coleta, com uma assistente virtual com IA generativa integrada.

Desenvolvido como desafio em parceria com **Eurofarma/Lactare**.

---

## 📱 Sobre o projeto

O app resolve a fricção do processo de doação de leite humano em um fluxo único: localizar um banco de leite próximo, cumprir os exames pré-doação exigidos, agendar a coleta e acompanhar o próprio histórico — com uma assistente virtual disponível para tirar dúvidas a qualquer momento.

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
- Organização **feature-first** inspirada em Clean Architecture, com camadas `domain` / `data` / `presentation` por feature

**Backend** ([`LactareConnect-backend`](https://github.com/Fiszbejn/LactareConnect-backend))
- **NestJS** (TypeScript) com **TypeORM** sobre **Oracle Database**
- Autenticação **JWT** + autorização **RBAC** (papéis `nutriz`/`administrador`, incluindo regra "dono do próprio registro")
- API REST documentada via **Swagger**, containerizada com **Docker Compose**
- Assistente virtual **Lila** integrada ao **Google Gemini** (`@google/genai`), com prompt de sistema construído dinamicamente a partir da FAQ cadastrada

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
- **RBAC granular por método HTTP**: o backend libera `POST` para a nutriz apenas nos próprios registros e mantém `GET` (histórico de conversas) restrito a administradores — regra de privacidade garantida estruturalmente na API, não só na camada visual do app.
- **Escopo sempre validado contra o contrato real da API**: funcionalidades sem respaldo real no backend (ex: regras de pontuação fictícias, campos inexistentes) foram conscientemente cortadas ou ajustadas, em vez de mockadas.
- **Tratamento de casos de borda reais**: geolocalização sem sinal de GPS, contas sem endereço cadastrado, timestamps em UTC vindos do backend, navegação aninhada com `go_router` — todos identificados testando o app de ponta a ponta, não só por análise estática.

## 🛠️ Skills demonstradas

- Arquitetura de app mobile em camadas (feature-first / Clean Architecture) com Flutter e Riverpod
- Design e consumo de API REST com autenticação JWT e autorização baseada em papéis (RBAC)
- Integração com serviços externos: geolocalização, seleção de arquivos, mapas (OpenStreetMap) e IA generativa (Google Gemini)
- Modelagem de backend com NestJS, TypeORM e banco relacional Oracle
- Containerização com Docker e Docker Compose
- Depuração e correção de bugs reais de integração cliente-servidor (não só erros de compilação)

---

<br/>
<br/>

<p align="center">
  <img src="docs/assets/eurofarma-logo.png" alt="Eurofarma" height="40" />
  &emsp;&emsp;×&emsp;&emsp;
  <img src="docs/assets/fiap-logo.png" alt="FIAP" height="40" />
</p>
