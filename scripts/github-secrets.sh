#!/usr/bin/env bash
# =============================================================================
# Mostra os valores das variáveis de conexão do banco (App Settings do Web App)
# para copiar e colar manualmente nos Secrets do repositório no GitHub:
#   Settings → Secrets and variables → Actions → New repository secret
#
# Pré-requisitos:
#   - deploy-azure.sh já executado
#   - az login
#
# Atenção: a senha aparece no terminal. Não rode em tela compartilhada
# e limpe o terminal depois (clear).
#
# Uso:
#   bash scripts/github-secrets.sh
# =============================================================================
set -euo pipefail

RESOURCE_GROUP_NAME="rg-checkpoint05"
WEBAPP_NAME="rm563045-library-checkpoint05"

SECRETS=(
  SPRING_DATASOURCE_URL
  SPRING_DATASOURCE_USERNAME
  SPRING_DATASOURCE_PASSWORD
)

for name in "${SECRETS[@]}"; do
  value=$(az webapp config appsettings list \
    --name "$WEBAPP_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --query "[?name=='$name'].value | [0]" \
    --output tsv)

  echo "Name:   $name"
  echo "Secret: $value"
  echo
done