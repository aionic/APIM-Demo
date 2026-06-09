# APIM Demo for Kong-to-APIM Migration

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.9-623CE4.svg)](https://www.terraform.io/)
[![Azure](https://img.shields.io/badge/Azure-API%20Management-0078D4.svg)](https://learn.microsoft.com/azure/api-management/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A batteries-included Terraform demo for showcasing Azure API Management (APIM) Standard v2 as a migration target from Kong. The sample is designed for a customer-facing demo with:

- APIM Standard v2 and developer portal ready posture
- IP-restricted ingress for the demo gateway
- Entra ID / OAuth2 auth server wiring and subscription flow
- Key Vault-backed named values and secret handling
- Lightweight sample APIs (weather, time, echo, and an AI-style path)
- Log Analytics diagnostics and traceability for monitoring and auditability
- Managed identity-driven access for Key Vault and AI backend resources

## What this repo provisions

- Resource Group
- Log Analytics workspace for diagnostics
- Key Vault + generated demo secret
- APIM Standard v2 with managed identity
- OAuth authorization server for Microsoft identity
- Sample APIs and products/subscriptions
- AI/OpenAI-style backend wiring for the LLM demo path

## Quick start

Prerequisites:

- Azure CLI authenticated with a subscription that can create APIM, Key Vault, Log Analytics, and Cognitive Services resources
- Terraform >= 1.9

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

For a first-run demo, update `allowed_ip_addresses` in `variables.tf` or override it with your public IPv4 address before applying.

## Demo narrative

1. Show the APIM gateway fronting public APIs and the developer portal.
2. Demonstrate IP-restricted ingress and subscription-based access.
3. Walk through Key Vault-backed named values and secret references in policies.
4. Show traceability and diagnostics in Log Analytics.
5. Showcase the AI-style path through APIM as an LLM-facing front door.

## Architecture overview

See [docs/architecture.md](docs/architecture.md) for the full architecture, identity flow, policy story, and monitoring design.

## Repository layout

- `main.tf` — core resource graph and APIM module wiring
- `locals.tf` — policy snippets, API map, and derived demo values
- `variables.tf` — demo configuration surface
- `specs/` — lightweight OpenAPI sample definitions
- `docs/architecture.md` — architecture and deployment notes

## Validation notes

The current Terraform path has been validated with:

```bash
terraform fmt -recursive
terraform validate
terraform plan
```

If you need a clean live deployment path in your tenant, re-run the apply after reviewing the APIM policy and network restrictions for your subscription.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
