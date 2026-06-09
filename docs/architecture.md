# Architecture and Demo Design

## Solution summary

This repository provisions a Terraform-first Azure API Management (APIM) demo that aligns to a Kong-to-APIM migration story. The deployment uses Azure Verified Modules where practical, with APIM Standard v2 as the public ingress layer and Azure-native services for identity, secrets, diagnostics, and sample backend experiences.

## Core topology

```text
Internet / Customer browser
        |
        v
  Azure APIM Standard v2
   - IP allowlist ingress
   - OAuth / Entra ID auth
   - Policy snippets + named values
   - Trace / correlation headers
   |
   +--> weather / time / echo sample APIs
   +--> AI-style LLM front-door path
   |
   +--> Key Vault (secret references)
   +--> Log Analytics (diagnostics, audit, usage)
```

## Resource flow

1. Terraform creates a Resource Group, Log Analytics workspace, Key Vault, and the APIM service.
2. APIM uses a managed identity to access Key Vault-backed values and backend resources.
3. Diagnostic settings stream APIM gateway, portal, and audit signals to Log Analytics.
4. Public APIs are exposed through APIM with lightweight OpenAPI definitions and policies for tracing, headers, and IP filtering.
5. The demo path is structured to support a future Foundry / Azure OpenAI backend with APIM load-balancing and traceability.

## Security and identity story

- APIM public ingress is restricted through a configurable allowlist of IP addresses or ranges.
- OAuth2 / Entra ID configuration is set up as an authorization server in APIM for the demo narrative.
- Key Vault-backed named values and secret references support a clean secret-management story for the customer.
- All Azure resource access from APIM is designed to rely on managed identity rather than embedded secrets.

## Policy and observability story

- Policy snippets demonstrate IP filtering, named-value references, header injection, and trace statements.
- Diagnostic settings push runtime and audit signals to Log Analytics for monitoring and usage analysis.
- The design supports user-level traceability, correlation IDs, and the kind of observability expected in an LLM-facing gateway path.

## Demo considerations

- The current demo is intentionally lightweight and single-region for easy customer deployment.
- The AI/LLM path is wired as an APIM-fronted backend flow rather than a full orchestration stack, keeping the scenario easy to show in a customer session.
- The current Terraform path is already validated locally; a live apply in your tenant should be used to confirm the final runtime behavior of your subscribed APIM and policy configuration.

## Recommended next steps

1. Replace the placeholder AI backend with the real Foundry / Azure OpenAI endpoint once the customer wants a production-like LLM deployment path.
2. Add a small backend service or public API endpoint if you want richer sample responses for the weather/time/demo story.
3. Extend the diagnostics with workbooks, alerts, or dashboards for a full operations narrative.
