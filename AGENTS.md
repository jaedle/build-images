## Automation / Scripting

- Use [taskfile](https://taskfile.dev/) for automation
- Do not write inline bash in GitHub Actions, use taskfile instead
- Provide a local task `world` to build images, run validations, etc.

## Docker images

- Favor curl over wget

## CI/CD Pipeline

- make sure used GitHub Actions have the most recent major version