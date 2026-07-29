# ADR 0001 — Arquitetura do app Flutter (LactareConnect)

## Status
Aceito.

## Contexto
O backend (NestJS + TypeORM + Oracle) já está pronto e validado, com 17 entidades, autenticação JWT e RBAC em 3 grupos de permissão (ver Swagger em `/docs`). A maior parte das regras de negócio (idade mínima, checklist de exames pré-doação, cálculo/crédito de gotinhas, bloqueio de duplicidade, RBAC) já é validada no backend. O app Flutter consome essa API e cobre, nesta fase, apenas as telas da doadora (o painel administrativo foi desenhado em layout web e fica fora deste escopo).

## Decisões

### 1. Gerenciamento de estado: Riverpod
Alternativas consideradas: Provider, Bloc/Cubit, GetX.
Escolhido por não depender de `BuildContext`, ser mais testável, e porque `AsyncValue` cobre bem o padrão repetido no app (loading/erro/dados vindos da API) sem código repetido em cada tela.

### 2. Organização: feature-first com Clean Architecture pragmática
```
lib/
  core/            # theme, network (Dio), router (go_router), error, widgets compartilhados
  features/
    <feature>/
      data/        # datasources (Dio), models (DTOs), implementação do repositório
      domain/      # entities, interface do repositório, usecases (só onde há regra de negócio real)
      presentation/ # screens, providers (Riverpod), widgets
```
Features: `auth`, `doacao`, `conta`, `faq`, `chat`, `recompensas`.

**Por que "pragmática"**: como o backend já valida a maior parte da regra de negócio, criar uma classe `usecase` para toda ação de CRUD simples geraria boilerplate sem valor (um usecase que só chama `repository.getX()` é considerado anti-padrão / "cargo cult" de Clean Architecture). Optamos por:
- `domain/entities` e `domain/repositories` (interface abstrata) sempre existem — é barato e permite mockar em teste.
- `domain/usecases` só é criado onde há orquestração/regra real do lado do cliente: sessão/login (chamar `/v1/auth/login`, guardar token com segurança, guardar tipo de usuário), guard de rota por RBAC, acumular/submeter o wizard de cadastro em 2 passos, e ações inline do chat que disparam agendamento (orquestração entre features).
- Para as demais entidades (Recompensa, PerguntaFrequente, BancoLeite, etc.), o provider chama o repositório diretamente.

Essa abordagem é reconhecida no mercado como aplicação madura de Clean Architecture (não uma versão "fraca") — aplicar a camada de usecase apenas onde ela agrega valor real é a orientação pública de consultorias Flutter como a Very Good Ventures, e é coerente com o objetivo original da Dependency Rule (testabilidade e flexibilidade), não com uma checklist rígida de camadas.

### 3. Navegação: go_router
Escolhido pelo mecanismo de `redirect`, que cobre o guard de RBAC/sessão (sem token → login; usuário tentando acessar rota que não é sua → bloqueio) de forma centralizada, em vez de espalhar verificações pelo código de cada tela.

### 4. Cliente HTTP: Dio
Escolhido pelos interceptors, que injetam o header `Authorization: Bearer <token>` automaticamente em toda chamada e tratam erro 401 de forma global (ex.: deslogar o usuário), evitando repetir essa lógica nas chamadas às ~17 entidades da API.

## Consequências
- Menos boilerplate do que Clean Architecture "de livro" aplicada a tudo, ao custo de exigir julgamento caso a caso sobre quando criar um usecase.
- Dependência de pacotes de terceiros (`flutter_riverpod`, `go_router`, `dio`, `flutter_secure_storage`) além do SDK padrão do Flutter.
- A fonte de marca oficial ("Loos Normal Bold") ainda não foi licenciada; usa-se `google_fonts` com Public Sans como stand-in (mesma substituição já usada nos wireframes).
