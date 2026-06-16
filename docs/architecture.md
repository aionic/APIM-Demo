# Architecture

## Solution summary

This repository provisions an Azure API Management platform using Terraform modules and AzAPI. APIM Standard v2 serves as the public API gateway and integrates with Entra ID, Key Vault, Log Analytics, Azure Managed Grafana, and an AI backend endpoint pattern.

## Core topology

```mermaid
flowchart LR
    C[Client / Developer Portal User] --> APIM[Azure API Management Standard v2]

    subgraph APIM_LAYER["API Gateway Layer"]
      APIM --> WEATHER[Weather API]
      APIM --> TIME[Time API]
      APIM --> ECHO[Echo API]
      APIM --> AIAPI[AI Gateway API]
    end

    APIM --> AUTH[Microsoft Entra ID OAuth2]
    APIM --> KV[Azure Key Vault]
    APIM --> LAW[Log Analytics Workspace]
    AIAPI --> AIBACKEND[Azure OpenAI / AI Endpoint]
```

## Deployment topology

```mermaid
flowchart TD
    TF[Terraform Apply] --> RG[Resource Group]
    TF --> APIM[APIM Service via AzAPI]
    TF --> KV[Key Vault]
    TF --> LAW[Log Analytics]
    TF --> AOAI[Azure OpenAI]
    TF --> GRAFANA[Azure Managed Grafana]
    TF --> WB[Workbook Deployment]

    APIM --> APIS[APIs + Products + Subscriptions]
    APIM --> OAuth[Entra OAuth + Portal IdP]
    APIM --> RBAC[Managed Identity RBAC]
    APIS --> POL[Global and API Policies]
```

## Solution flow

1. Terraform composes three modules (`platform`, `apim`, `observability`) for clear separation of concerns.
2. Foundational resources are created first: Resource Group, Log Analytics, Key Vault, and AI endpoint resource.
3. APIM is configured with managed identity, named values, products, subscriptions, and API imports from OpenAPI specs.
4. Observability resources provision workbook queries and Azure Managed Grafana with managed identity access to Log Analytics.
5. Inbound policy applies correlation/tracing headers before forwarding to backend APIs.
6. Secret-backed values are stored in Key Vault and consumed by APIM policy/runtime configuration.
7. Telemetry and audit logs are sent to Log Analytics for operational monitoring.

## Request and telemetry flow

```mermaid
sequenceDiagram
  autonumber
  participant Client
  participant APIM as APIM Gateway
  participant Backend as Backend API
  participant LA as Log Analytics
  Client->>APIM: HTTPS call + subscription key
  APIM->>APIM: Evaluate policies
  APIM->>Backend: Forward request
  Backend-->>APIM: Response
  APIM-->>Client: Response payload
  APIM->>LA: Gateway + diagnostics logs
```

## Security and identity

- OAuth2 authorization server is configured against Microsoft Entra ID.
- Managed identity is used for APIM access to dependent Azure resources.
- Secrets are handled through Key Vault and APIM named values.

## Policy and observability

- Policy snippets implement network controls, header enrichment, and trace signals.
- Diagnostic settings capture APIM gateway and developer portal audit logs.
- Log Analytics is the central sink for runtime and operational telemetry.
- Azure Managed Grafana reads Log Analytics with managed identity (Monitoring Reader role).

## Terraform alignment

- Provider and Terraform versions are constrained in `versions.tf`.
- Resources are decomposed into module boundaries, with APIM specifics isolated in the `apim` module.
- State artifacts are excluded from source control with `.gitignore`.
- Recommended deployment pattern is `plan -out` followed by `apply` on the saved plan.
- Local Entra values belong in `env/demo.auto.tfvars`; remote backend settings belong in `env/backend.azurerm.hcl`.

## Recommended next steps

1. Move Terraform state to a remote backend (Azure Storage) for collaborative deployments.
2. Replace placeholder AI endpoint configuration with your production model deployment.
3. Add alerting/workbooks on top of Log Analytics for operational readiness.
