# Blue-Green Deployment

A containerized deployment project demonstrating the Blue-Green Deployment strategy using Docker Compose, Nginx, and Node.js.

The project runs two application versions simultaneously and routes incoming traffic through Nginx. A deployment script switches traffic to the selected version after checking application health and validating the Nginx configuration.

## Architecture

```text
                 Client
                   |
                   v
          Nginx Reverse Proxy
          127.0.0.1:18080
                   |
             Traffic Routing
              /          \
             v            v
       Blue (v1)       Green (v2)
       Port 3000       Port 3000
```

Both application containers run on a private Docker network. Only the Nginx proxy publishes a host port, bound to localhost.

## Tech Stack

- Node.js and Express
- Docker and Docker Compose
- Nginx reverse proxy
- Bash deployment and rollback scripts

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

- Docker Engine or Docker Desktop with Docker Compose
- `curl`
- Bash and Python 3 on the host

## Getting Started

Clone the repository and enter the project directory:

```bash
git clone <your-repository-url>
cd blue-green-deployment
```

Build and start the application containers:

```bash
docker compose up -d --build
```

Check container status:

```bash
docker compose ps
```

Open the application through the Nginx proxy:

```bash
curl http://127.0.0.1:18080/
```

The initial Nginx configuration routes traffic to Blue (v1).

## Application Endpoints

| Endpoint | Description |
|---|---|
| `/` | Returns application version, color, and status |
| `/health` | Returns application health and version |
| `/proxy-health` | Checks whether the Nginx proxy responds |

## Deploy a New Version

Deploy Green (v2):

```bash
./deploy.sh green
```

The deployment script:

1. Checks the target application's health endpoint.
2. Saves the current Nginx configuration.
3. Updates the upstream target.
4. Validates the Nginx configuration.
5. Reloads Nginx.
6. Verifies the active application version.
7. Restores the previous configuration if deployment fails.

Verify the active version:

```bash
curl -s http://127.0.0.1:18080/
```

## Rollback

Return traffic to Blue (v1):

```bash
./rollback.sh
```

Verify the result:

```bash
curl -s http://127.0.0.1:18080/
```

The Blue and Green application containers remain running during traffic switching and rollback.

## Validation and Testing

The following scenarios have been tested locally:

- Blue (v1) and Green (v2) run simultaneously.
- Both application health endpoints respond successfully.
- Nginx routes traffic to Blue and Green.
- Deployment to Green succeeds.
- Rollback to Blue succeeds.
- Unsupported deployment targets are rejected.
- An unavailable target fails its health check without changing the active route.

These are local functional tests, not a formal load test or a guarantee of zero downtime under every failure condition.

## Security and Scope

- The proxy is bound to `127.0.0.1:18080`, not exposed on all host interfaces.
- Application containers communicate over a Docker network.
- The current deployment scripts are designed for this local project setup.
- Production deployment would require additional controls, such as automated integration tests, concurrency protection, monitoring, and a server-specific deployment configuration.

## Cleanup

Stop the services created by this Compose project:

```bash
docker compose down
```

This command removes the Compose containers and network but does not remove named volumes. It does not remove the separately created standalone test containers.

## License

Choose a license before publishing this project publicly.
