# AWS ECS n8n

## Setup

### Localhost

You will need Docker and Docker Compose, and optionally VS Code devcontainers:

1. Copy `.env.example` to `.env` and update the values as needed.
2. Run `make localhost`.
3. Access n8n at http://localhost:5678.

## Deployment

The deployment uses AWS ECS with the following components:
- ECS Fargate tasks for n8n
- PostgreSQL database for workflow storage
- Load balancer with HTTPS support

## Development

To set up the development environment, run the following commands:

```bash
make localhost
```
