# Blue-Green Deployment

A hands-on implementation of the [roadmap.sh Blue-Green Deployment project](https://roadmap.sh/projects/blue-green-deployment), demonstrating how to run two application versions in separate Docker containers and switch traffic safely using Nginx.

## Overview

Blue-Green Deployment is a release strategy that runs two application environments simultaneously:

- **Blue:** the current stable version (`v1`).
- **Green:** the new application version (`v2`).

The new version can be started and health-checked before traffic is switched to it. If a rollback is needed, traffic can be routed back to the previous version without stopping the application containers.

This project implements the strategy locally using Docker Compose, Node.js, Express, and Nginx.

## Architecture

```text
                  Client
                    |
                    v
             Nginx Reverse Proxy
             localhost:18080
                    |
             Traffic Switching
                /       \
               v         v
          Blue (v1)   Green (v2)
          Express     Express
          Port 3000   Port 3000
```

Both application containers run simultaneously on a Docker network. Nginx acts as the entry point and routes requests to the selected version.

Only the Nginx proxy publishes a host port, bound to `127.0.0.1:18080`.

## Tech Stack

- **Node.js & Express** — web application and health endpoint
- **Docker** — containerized application versions
- **Docker Compose** — multi-container orchestration
- **Nginx** — reverse proxy and traffic switching
- **Bash & Python 3** — deployment automation and configuration updates

## Project Structure

```text
blue-green-deployment/
├── app/
│   ├── Dockerfile
│   ├── package.json
│   └── server.js
├── nginx/
│   └── default.conf
├── compose.yaml
├── deploy.sh
├── rollback.sh
└── README.md
```

## Prerequisites

- Docker with Docker Compose
- Bash
- Python 3
- `curl`

## Getting Started

### 1. Clone the repository

```bash
git clone <your-repository-url>
cd blue-green-deployment
```

Replace `<your-repository-url>` with your GitHub repository URL.

### 2. Start the application environments

```bash
docker compose up -d --build
```

Check the container status:

```bash
docker compose ps
```

The Blue, Green, and Nginx containers should be running.

### 3. Verify the active version

The initial Nginx configuration routes traffic to Blue (`v1`).

```bash
curl http://127.0.0.1:18080/
```

Expected response:

```json
{
  "application": "blue-green-demo",
  "version": "v1",
  "color": "blue",
  "status": "running"
}
```

The response also includes a timestamp.

## Application Endpoints

| Endpoint        | Purpose                                                             |
| --------------- | ------------------------------------------------------------------- |
| `/`             | Returns application version, color, status, and release information |
| `/health`       | Reports application health and version                              |
| `/proxy-health` | Checks whether the Nginx proxy responds                             |

## Deployment Workflow

### 1. Deploy Green

Run:

```bash
./deploy.sh green
```

The script performs these steps:

1. Checks the target application's health.
2. Saves the current Nginx configuration.
3. Updates the traffic destination.
4. Validates the Nginx configuration.
5. Reloads Nginx.
6. Verifies the active application version.
7. Attempts to restore the previous configuration if deployment fails.

Verify the result:

```bash
curl -s http://127.0.0.1:18080/
```

The response should identify Green (`v2`) and include the `green-release` and `deployment-v2` fields.

### 2. Roll Back to Blue

Run:

```bash
./rollback.sh
```

The script routes traffic back to Blue (`v1`).

Verify the result:

```bash
curl -s http://127.0.0.1:18080/
```

The response should identify Blue (`v1`).

## Testing

The following scenarios have been tested locally:

- Blue and Green run as separate application containers.
- Both application health endpoints respond successfully.
- Nginx routes traffic to Blue and Green.
- Deployment from Blue to Green succeeds.
- Rollback from Green to Blue succeeds.
- Unsupported deployment targets are rejected.
- An unavailable target fails its health check before the traffic configuration changes.
- The active version remains unchanged when the target health check fails.

These tests verify the deployment workflow's basic functionality. They are not formal load tests or proof of zero downtime under every failure condition.

## Scope and Limitations

This project focuses on the core Blue-Green Deployment workflow required by roadmap.sh.

- Deployment and rollback are executed manually through local scripts.
- The deployment scripts assume the existing Docker Compose container names and local project configuration.
- CI/CD integration and production-server deployment have not been implemented.
- Monitoring and production-grade observability are not included.
- Configuration rollback is attempted when a deployment step fails, but this is not a guarantee against every possible failure.

## Future Improvements

- Automate deployment through a CI/CD pipeline.
- Deploy the application to a remote server.
- Add monitoring and deployment alerts.
- Add automated integration tests.
- Improve deployment locking and concurrent execution safety.

## License

No license has been selected yet. Add a license file before distributing the project under an open-source license.
