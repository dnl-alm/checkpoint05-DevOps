# Library API · Checkpoint 05 DevOps

API REST de uma biblioteca, feita em **Java 21 + Spring Boot 3**, publicada na Azure como **Web App (App Service)** e com dados em um **Azure SQL Database**. O deploy é automático via **GitHub Actions** a cada push na branch `main`, e a aplicação é monitorada pelo **Application Insights**.

---

## 1. Descrição da solução

A API gerencia **autores** e os **livros** escritos por eles. As duas tabelas têm uma relação **1:N**: um autor pode ter vários livros, e cada livro pertence a exatamente um autor.

| Tabela    | Colunas                                             | Observação                                  |
|-----------|-----------------------------------------------------|---------------------------------------------|
| `t_autor` | `id`, `nome`, `nacionalidade`                       | PK `id` (IDENTITY)                          |
| `t_livro` | `id`, `titulo`, `ano_publicacao`, `autor_id`        | PK `id` (IDENTITY), **FK `autor_id` → `t_autor.id`** |

Regras de negócio:
- Um livro só pode ser cadastrado para um autor existente. Caso contrário, a API responde **404**.
- Um autor que ainda tem livros não pode ser excluído. Nesse caso, a API responde **409 Conflict**.
- Campos obrigatórios em branco retornam **400**, com a lista dos campos inválidos.

### Tecnologias

| Camada         | Tecnologia                                      |
|----------------|-------------------------------------------------|
| Linguagem      | Java 21                                         |
| Framework      | Spring Boot 3.5 (Web, Data JPA, Validation)     |
| Banco de dados | Azure SQL Database (driver `mssql-jdbc`)        |
| Produtividade  | Lombok                                          |
| Nuvem          | Azure App Service (Linux, F1), Azure SQL, Application Insights |
| CI/CD          | GitHub Actions                                  |

### Estrutura do projeto

```
.
├── docs/
│   ├── arquitetura.png / .svg                 # desenho da arquitetura
│   └── library-api.postman_collection.json    # JSON das operações (Postman)
├── scripts/
│   ├── deploy-azure.sh                        # script Azure CLI (provisionamento + CI/CD)
│   ├── github-secrets.sh                      # mostra os valores para os Secrets do GitHub
│   └── ddl.sql                                # DDL das tabelas
├── src/main/java/br/com/library/
│   ├── controller/      # endpoints REST
│   ├── dto/
│   │   ├── request/     # dados de entrada
│   │   └── response/    # dados de saída
│   ├── entity/          # entidades JPA (t_autor, t_livro)
│   ├── exception/       # tratamento de erros (404, 409, 400)
│   ├── repository/      # Spring Data JPA
│   ├── service/         # regras de negócio
│   └── BibliotecaApplication.java
├── src/main/resources/application.properties
└── pom.xml
```

---

## 2. Arquitetura da solução

![Arquitetura](/docs/arquitetura.svg)

Fluxo:
1. O desenvolvedor faz **push** do código para o GitHub.
2. O **GitHub Actions** compila o projeto com Maven e publica o `.jar` no **Web App**.
3. O **cliente** (Postman ou navegador) chama a API por **HTTPS**.
4. O Web App acessa o **Azure SQL Database** via **JDBC na porta 1433**.
5. A telemetria (requisições, tempo de resposta, erros) vai para o **Application Insights**.

Todos os recursos ficam no grupo `rg-checkpoint05`, na região **canadacentral**.

---

## 3. How to: implantação na Azure (passo a passo)

### 3.1 Pré-requisitos

- Conta na Azure com uma assinatura ativa.
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) instalada. Outra opção é usar o **Azure Cloud Shell (Bash)** no portal, que já vem com tudo.
- Conta no GitHub com o repositório `dnl-alm/checkpoint05-DevOps`.
- Git instalado.

### 3.2 Colocar o código no GitHub

O `pom.xml` precisa ficar na **raiz** do repositório, porque é lá que o workflow do GitHub Actions procura.

```bash
git clone https://github.com/dnl-alm/checkpoint05-DevOps.git
cd checkpoint05-DevOps
# copie todos os arquivos do projeto para esta pasta
git add .
git commit -m "Library API"
git push origin main
```

### 3.3 Fazer login na Azure

```bash
az login
az account show --output table   # confirme que é a assinatura certa
```

### 3.4 Revisar os nomes no script

Abra `scripts/deploy-azure.sh`. Dois nomes precisam ser **únicos em toda a Azure**: se alguém já tiver usado, o comando falha. Se for o caso, acrescente seu RM no final.

```bash
WEBAPP_NAME="library-checkpoint05"        # vira library-checkpoint05.azurewebsites.net
SQL_SERVER_NAME="sql-server-checkpoint05" # vira sql-server-checkpoint05.database.windows.net
```

A região é sempre `LOCATION="canadacentral"`, e todos os recursos usam essa variável.

### 3.5 Executar o script

A senha do banco **não fica no script**, porque ele vai para o GitHub. Você pode passá-la por variável de ambiente; se não passar, o script pergunta.

```bash
export SQL_ADMIN_PASSWORD='SuaSenhaForte@123'
bash scripts/deploy-azure.sh
```

> A senha precisa ter no mínimo 8 caracteres e usar 3 destes 4 grupos: maiúsculas, minúsculas, números e símbolos.

O script faz, nesta ordem:

| # | Etapa | Recurso criado |
|---|-------|----------------|
| 1 | Registra os providers e instala a extensão do App Insights | — |
| 2 | Cria o grupo de recursos | `rg-checkpoint05` |
| 3 | Cria o SQL Server e o banco (tier Basic) | `sql-server-checkpoint05` / `db-checkpoint05` |
| 4 | Libera o acesso de serviços da Azure ao banco e, para testes, de qualquer IP | regras `AllowAzureServices` e `liberaGeral` |
| 5 | Cria o Application Insights | `ai-checkpoint05` |
| 6 | Cria o plano Linux F1 e o Web App Java 21 | `checkpoint05` / `library-checkpoint05` |
| 7 | Habilita a autenticação básica (SCM), usada pelo deploy do GitHub | — |
| 8 | Configura as variáveis de ambiente do app (conexão com o banco e App Insights) | App Settings |
| 9 | Conecta o Web App ao Application Insights | — |
| 10 | Cria o workflow do GitHub Actions no repositório | `.github/workflows/*.yml` |

Na etapa 10, o CLI mostra um **código** e pede que você autorize o acesso ao GitHub no navegador. Depois de autorizar, ele faz um commit do workflow no repositório e o primeiro deploy começa sozinho. Puxe esse commit para a sua máquina:

```bash
git pull origin main
```

### 3.6 Cadastrar os Secrets no GitHub

As variáveis de conexão com o banco também precisam existir no GitHub, para o build do GitHub Actions (e os testes) conseguir usá-las. Elas são copiadas manualmente das App Settings do Web App.

**1. Mostrar os valores**

```bash
bash scripts/github-secrets.sh
```

Saída:

```
Name:   SPRING_DATASOURCE_URL
Secret: jdbc:sqlserver://sql-server-checkpoint05.database.windows.net:1433;database=...

Name:   SPRING_DATASOURCE_USERNAME
Secret: user-checkpoint05

Name:   SPRING_DATASOURCE_PASSWORD
Secret: ********
```

> A senha aparece em texto puro. Rode num terminal só seu e use `clear` ao terminar.

**2. Cadastrar no repositório**

No GitHub, abra **Settings → Secrets and variables → Actions → New repository secret** e crie os três secrets abaixo, copiando cada valor da saída do script:

| Name | Secret |
|------|--------|
| `SPRING_DATASOURCE_URL` | valor de `SPRING_DATASOURCE_URL` |
| `SPRING_DATASOURCE_USERNAME` | valor de `SPRING_DATASOURCE_USERNAME` |
| `SPRING_DATASOURCE_PASSWORD` | valor de `SPRING_DATASOURCE_PASSWORD` |

**3. Passar os Secrets para o build no workflow**

No arquivo criado pelo script em `.github/workflows/` (ex.: `main_library-checkpoint05.yml`), adicione o bloco `env` ao passo de build do Maven:

```yaml
      - name: Build with Maven
        run: mvn clean install
        env:
          SPRING_DATASOURCE_URL: ${{ secrets.SPRING_DATASOURCE_URL }}
          SPRING_DATASOURCE_USERNAME: ${{ secrets.SPRING_DATASOURCE_USERNAME }}
          SPRING_DATASOURCE_PASSWORD: ${{ secrets.SPRING_DATASOURCE_PASSWORD }}
```

Faça commit e push dessa alteração. Um novo build começa automaticamente.

```bash
git add .github/workflows/
git commit -m "Secrets do banco no build"
git push origin main
```

> Os runners do GitHub usam IPs variáveis. Quem permite que eles alcancem o banco é a regra de firewall `liberaGeral`. Se ela for removida, os testes no Actions não conseguem conectar.

### 3.7 Criar as tabelas (DDL)

1. No portal da Azure, abra **SQL databases → db-checkpoint05 → Query editor (preview)**.
2. Entre com o usuário `user-checkpoint05` e a senha que você definiu.
3. Cole o conteúdo de [`scripts/ddl.sql`](scripts/ddl.sql) e clique em **Run**.
4. Confira no painel **Tables** que `dbo.t_autor` e `dbo.t_livro` apareceram.

> A aplicação também usa `ddl-auto=update`, então criaria as tabelas que faltassem. O DDL é a fonte oficial do schema. Como ele começa com `DROP TABLE IF EXISTS`, pode ser executado mais de uma vez.

### 3.8 Acompanhar o deploy

No GitHub, abra a aba **Actions** do repositório. O workflow tem duas etapas, **build** e **deploy**. Quando as duas ficarem verdes, a API está no ar.

Para ver os logs da aplicação subindo:

```bash
az webapp log tail --name library-checkpoint05 --resource-group rg-checkpoint05
```

> No plano F1 (gratuito), a primeira requisição depois de um tempo parado pode levar de 30 a 60 segundos, porque o app "acorda". Isso é normal.

### 3.9 Testar a API

```bash
curl https://library-checkpoint05.azurewebsites.net/autores
```

Para testar tudo de uma vez, importe [`docs/library-api.postman_collection.json`](docs/library-api.postman_collection.json) no Postman (**Import → File**). A variável `baseUrl` já aponta para o Web App.

### 3.10 Ver o monitoramento

No portal, abra **Application Insights → ai-checkpoint05**:
- **Live Metrics**: requisições em tempo real.
- **Transaction search**: cada chamada, com tempo de resposta e status.
- **Failures**: erros 4xx e 5xx.

### 3.11 Remover tudo (para não gerar custo)

```bash
az group delete --name rg-checkpoint05 --yes --no-wait
```

### Problemas comuns

| Sintoma | Causa provável e solução |
|---------|--------------------------|
| `...name is already in use` / `...not available` | `WEBAPP_NAME` ou `SQL_SERVER_NAME` já existem na Azure. Troque o nome, por exemplo acrescentando seu RM. |
| `The maximum number of Free ServerFarms allowed...` | Só é permitido um plano F1 Linux por região. Apague o plano antigo ou use `--sku B1`. |
| App retorna **503 / Application Error** | Veja `az webapp log tail`. Geralmente é erro de conexão com o banco: confira as App Settings `SPRING_DATASOURCE_*`. |
| `Cannot open server ... requested by the login` | Falta a regra de firewall do SQL para o seu IP ou para os serviços da Azure. |
| Workflow falha no *build* | O `pom.xml` não está na raiz do repositório. |
| Build falha com `Could not resolve placeholder 'SPRING_DATASOURCE_URL'` | Os Secrets não foram cadastrados ou o bloco `env` não foi adicionado ao workflow (seção 3.6). |

---

## 4. Endpoints e JSON das operações

URL base: `https://library-checkpoint05.azurewebsites.net`

| Método | Rota                   | Descrição                     | Sucesso |
|--------|------------------------|-------------------------------|---------|
| GET    | `/autores`             | Lista autores                 | 200 |
| GET    | `/autores/{id}`        | Busca um autor                | 200 |
| GET    | `/autores/{id}/livros` | Lista os livros de um autor   | 200 |
| POST   | `/autores`             | Cria um autor                 | 201 |
| PUT    | `/autores/{id}`        | Atualiza um autor             | 200 |
| DELETE | `/autores/{id}`        | Exclui um autor sem livros    | 204 |
| GET    | `/livros`              | Lista livros                  | 200 |
| GET    | `/livros/{id}`         | Busca um livro                | 200 |
| POST   | `/livros`              | Cria um livro                 | 201 |
| PUT    | `/livros/{id}`         | Atualiza um livro             | 200 |
| DELETE | `/livros/{id}`         | Exclui um livro               | 204 |

### Autores

**POST** `/autores` → `201 Created`
```json
{
  "nome": "Machado de Assis",
  "nacionalidade": "Brasileira"
}
```
Resposta:
```json
{
  "id": 1,
  "nome": "Machado de Assis",
  "nacionalidade": "Brasileira"
}
```

**GET** `/autores` → `200 OK`
```json
[
  {
    "id": 1,
    "nome": "Machado de Assis",
    "nacionalidade": "Brasileira"
  }
]
```

**GET** `/autores/1` → `200 OK`
```json
{
  "id": 1,
  "nome": "Machado de Assis",
  "nacionalidade": "Brasileira"
}
```

**GET** `/autores/1/livros` → `200 OK`
```json
[
  {
    "id": 1,
    "titulo": "Dom Casmurro",
    "anoPublicacao": 1899,
    "autor": { "id": 1, "nome": "Machado de Assis", "nacionalidade": "Brasileira" }
  }
]
```

**PUT** `/autores/1` → `200 OK`
```json
{
  "nome": "Joaquim Maria Machado de Assis",
  "nacionalidade": "Brasileira"
}
```
Resposta:
```json
{
  "id": 1,
  "nome": "Joaquim Maria Machado de Assis",
  "nacionalidade": "Brasileira"
}
```

**DELETE** `/autores/2` → `204 No Content`, sem corpo.

Se o autor tiver livros, a resposta é `409 Conflict`:
```json
{
  "type": "about:blank",
  "title": "Conflict",
  "status": 409,
  "detail": "Autor possui livros cadastrados e não pode ser excluído",
  "instance": "/autores/1"
}
```

### Livros

**POST** `/livros` → `201 Created`
```json
{
  "titulo": "Dom Casmurro",
  "anoPublicacao": 1899,
  "autorId": 1
}
```
Resposta:
```json
{
  "id": 1,
  "titulo": "Dom Casmurro",
  "anoPublicacao": 1899,
  "autor": { "id": 1, "nome": "Machado de Assis", "nacionalidade": "Brasileira" }
}
```

**GET** `/livros` → `200 OK`
```json
[
  {
    "id": 1,
    "titulo": "Dom Casmurro",
    "anoPublicacao": 1899,
    "autor": { "id": 1, "nome": "Machado de Assis", "nacionalidade": "Brasileira" }
  }
]
```

**GET** `/livros/1` → `200 OK`
```json
{
  "id": 1,
  "titulo": "Dom Casmurro",
  "anoPublicacao": 1899,
  "autor": { "id": 1, "nome": "Machado de Assis", "nacionalidade": "Brasileira" }
}
```

**PUT** `/livros/1` → `200 OK`
```json
{
  "titulo": "Dom Casmurro (edição revisada)",
  "anoPublicacao": 1900,
  "autorId": 1
}
```
Resposta:
```json
{
  "id": 1,
  "titulo": "Dom Casmurro (edição revisada)",
  "anoPublicacao": 1900,
  "autor": { "id": 1, "nome": "Machado de Assis", "nacionalidade": "Brasileira" }
}
```

**DELETE** `/livros/1` → `204 No Content`, sem corpo.

### Erros

`404 Not Found`, quando o recurso não existe:
```json
{
  "type": "about:blank",
  "title": "Not Found",
  "status": 404,
  "detail": "Autor 99 não encontrado",
  "instance": "/livros"
}
```

`400 Bad Request`, quando há campos obrigatórios em branco:
```json
{
  "type": "about:blank",
  "title": "Bad Request",
  "status": 400,
  "detail": "Dados inválidos",
  "instance": "/livros",
  "campos": {
    "titulo": "must not be blank",
    "autorId": "must not be null"
  }
}
```

---

## 5. Rodando localmente (opcional)

Requer JDK 21 e Maven, e o IP da sua máquina liberado no firewall do SQL (a regra `liberaGeral` já cobre isso).

```bash
export SPRING_DATASOURCE_URL='jdbc:sqlserver://sql-server-checkpoint05.database.windows.net:1433;database=db-checkpoint05;encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30;'
export SPRING_DATASOURCE_USERNAME='user-checkpoint05'
export SPRING_DATASOURCE_PASSWORD='SuaSenhaForte@123'
mvn spring-boot:run
```

A API sobe em `http://localhost:8080`.