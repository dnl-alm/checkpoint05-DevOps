#!/usr/bin/env bash
# =============================================================================
# Provisionamento na Azure da Library API (Spring Boot + Azure SQL)
#
# Cria, todos em canadacentral:
#   - Grupo de Recursos
#   - Azure SQL Server + Azure SQL Database (Basic)
#   - Application Insights
#   - App Service Plan (Linux, F1) + Web App (Java 21)
#   - Workflow do GitHub Actions para build e deploy automático
#
# Uso:
#   export SQL_ADMIN_PASSWORD='SuaSenhaForte@123'   # opcional; se não definir, o script pergunta
#   bash scripts/deploy-azure.sh
# =============================================================================
set -euo pipefail

RESOURCE_GROUP_NAME="rg-checkpoint05"
WEBAPP_NAME="rm563045-library-checkpoint05"
APP_SERVICE_PLAN="checkpoint05"
LOCATION="canadacentral"
RUNTIME="JAVA:21-java21"
GITHUB_REPO_NAME="dnl-alm/checkpoint05-DevOps"
BRANCH="main"
APP_INSIGHTS_NAME="ai-checkpoint05"

# Banco de dados
SQL_SERVER_NAME="sql-server-rm563045-checkpoint05"
SQL_DATABASE_NAME="db-checkpoint05"
SQL_ADMIN_USER="user-checkpoint05"

# A senha não fica escrita no script (ele vai para o GitHub).
# Requisitos da Azure: mínimo 8 caracteres e 3 destes 4 grupos:
# maiúsculas, minúsculas, números e símbolos.
if [[ -z "${SQL_ADMIN_PASSWORD:-}" ]]; then
  read -r -s -p "Senha do administrador do SQL Server: " SQL_ADMIN_PASSWORD
  echo
fi

JDBC_URL="jdbc:sqlserver://${SQL_SERVER_NAME}.database.windows.net:1433;database=${SQL_DATABASE_NAME};encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30;"

echo ">> Registrando providers e instalando extensões (idempotente)"
for ns in Microsoft.Web Microsoft.Sql Microsoft.Insights Microsoft.OperationalInsights Microsoft.ServiceLinker; do
  echo "   - $ns"
  az provider register --namespace "$ns" --wait
done

az extension add --name application-insights --upgrade --only-show-errors

echo ">> Criação do Grupo de Recursos"
az group create \
  --name "$RESOURCE_GROUP_NAME" \
  --location "$LOCATION"

echo ">> Criar o Azure SQL Server"
az sql server create \
  --name "$SQL_SERVER_NAME" \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --location "$LOCATION" \
  --admin-user "$SQL_ADMIN_USER" \
  --admin-password "$SQL_ADMIN_PASSWORD" \
  --enable-public-network true

echo ">> Criar o Azure SQL Database"
az sql db create \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --server "$SQL_SERVER_NAME" \
  --name "$SQL_DATABASE_NAME" \
  --service-objective Basic \
  --backup-storage-redundancy Local \
  --zone-redundant false

echo ">> Liberar acesso de serviços da Azure ao SQL (necessário para o Web App)"
az sql server firewall-rule create \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --server "$SQL_SERVER_NAME" \
  --name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

# -----------------------------------------------------------------------------
# A regra abaixo é apenas para fins de teste e estudo: libera QUALQUER IP
# (permite rodar o DDL e consultar o banco da sua máquina).
# Em produção, libere só o seu IP ou remova esta regra.
# -----------------------------------------------------------------------------
echo ">> Liberar acesso geral ao SQL (somente para testes)"
az sql server firewall-rule create \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --server "$SQL_SERVER_NAME" \
  --name liberaGeral \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 255.255.255.255

echo ">> Criar Application Insights"
az monitor app-insights component create \
  --app "$APP_INSIGHTS_NAME" \
  --location "$LOCATION" \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --application-type web

echo ">> Criar o Plano de Serviço"
az appservice plan create \
  --name "$APP_SERVICE_PLAN" \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --location "$LOCATION" \
  --sku F1 \
  --is-linux

echo ">> Criar o Serviço de Aplicativo"
az webapp create \
  --name "$WEBAPP_NAME" \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --plan "$APP_SERVICE_PLAN" \
  --runtime "$RUNTIME"

echo ">> Habilitar a autenticação Básica (SCM)"
az resource update \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --namespace Microsoft.Web \
  --resource-type basicPublishingCredentialsPolicies \
  --name scm \
  --parent "sites/$WEBAPP_NAME" \
  --set properties.allow=true

echo ">> Recuperar a String de Conexão do Application Insights"
CONNECTION_STRING=$(az monitor app-insights component show \
  --app "$APP_INSIGHTS_NAME" \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --query connectionString \
  --output tsv)

echo ">> Configurar as Variáveis de Ambiente do App e do Application Insights"
az webapp config appsettings set \
  --name "$WEBAPP_NAME" \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --settings \
    APPLICATIONINSIGHTS_CONNECTION_STRING="$CONNECTION_STRING" \
    ApplicationInsightsAgent_EXTENSION_VERSION="~3" \
    XDT_MicrosoftApplicationInsights_Mode="Recommended" \
    XDT_MicrosoftApplicationInsights_PreemptSdk="1" \
    SPRING_DATASOURCE_USERNAME="$SQL_ADMIN_USER" \
    SPRING_DATASOURCE_PASSWORD="$SQL_ADMIN_PASSWORD" \
    SPRING_DATASOURCE_URL="$JDBC_URL" \
    SERVER_PORT="80" \
  --output none

echo ">> Criar a conexão do Web App com o Application Insights"
az monitor app-insights component connect-webapp \
  --app "$APP_INSIGHTS_NAME" \
  --web-app "$WEBAPP_NAME" \
  --resource-group "$RESOURCE_GROUP_NAME"

echo ">> Configurar GitHub Actions para Build e Deploy automático"
az webapp deployment github-actions add \
  --name "$WEBAPP_NAME" \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --repo "$GITHUB_REPO_NAME" \
  --branch "$BRANCH" \
  --login-with-github

echo ">> Concluído."
echo "   API:   https://${WEBAPP_NAME}.azurewebsites.net/autores"
echo "   Banco: ${SQL_SERVER_NAME}.database.windows.net / ${SQL_DATABASE_NAME}"