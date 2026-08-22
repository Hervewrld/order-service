# order-service

A small order-processing app used as a learning vehicle for the full
SRE/DevOps lifecycle: Python/Bash → Git → Docker → Kubernetes → Terraform →
CI/CD → Prometheus/Grafana → chaos testing & postmortems.

Each folder below corresponds to one phase of that lifecycle. As each phase
is completed, its section here gets checked off and a short write-up is
linked from `docs/`.

## Architecture (grows over the phases)

```
client -> api (Flask/FastAPI) -> queue (Redis) -> worker -> db (Postgres)
```

## Project phases

- [x] **Phase 0 — App**: `src/api`, `src/worker`, `tests/`, `scripts/bootstrap.sh`
- [x] **Phase 1 — Git workflow**: branching, PRs, conventional commits (see `docs/git-workflow.md`)
- [x] **Phase 2 — Docker**: `docker/`, `docker-compose.yml`
- [x] **Phase 3 — Kubernetes**: `k8s/base` (raw manifests), `k8s/helm` (chart)
- [x] **Phase 4 — Terraform**: `terraform/modules`, `terraform/environments/{dev,prod}`
- [ ] **Phase 5 — CI/CD**: `.github/workflows/`
- [ ] **Phase 6 — Observability**: `monitoring/dashboards`, `monitoring/alerts`
- [ ] **Phase 7 — Chaos & postmortems**: `docs/postmortems/`

## Local development

```bash
./scripts/bootstrap.sh      # sets up local env and runs health checks
```

### With Docker

```bash
docker compose -f docker/docker-compose.yml up --build
```

Starts Redis, the API (`localhost:8000`, see `/docs` for Swagger UI), and the
worker together. `Ctrl+C` to stop, or `docker compose -f docker/docker-compose.yml down`
to remove the containers.

### With Kubernetes

Needs a local cluster (e.g. `minikube start`) and the images built into its
Docker daemon:

```bash
eval $(minikube docker-env)
docker build -f docker/api.Dockerfile -t order-service-api:local .
docker build -f docker/worker.Dockerfile -t order-service-worker:local .
```

Raw manifests:

```bash
kubectl apply -k k8s/base
kubectl port-forward svc/api 8000:8000   # http://localhost:8000/docs
kubectl delete -k k8s/base                # tear down
```

Helm chart (same result, templated):

```bash
helm install order-service k8s/helm/order-service
kubectl port-forward svc/api 8000:8000
helm uninstall order-service              # tear down
```

### With Terraform (real cloud infra)

`terraform/modules` has network/gke/redis/postgres modules; `terraform/environments/dev`
and `terraform/environments/prod` wire them together at different sizes. State
is remote (GCS bucket `order-service-tfstate-494251076287`).

```bash
gcloud auth application-default login   # once per machine
cd terraform/environments/dev
terraform init
terraform plan     # review before applying - this creates real, billable resources
terraform apply
```

`prod` is written for reference but sized for real usage (3 nodes, HA Redis,
bigger Postgres tier) - don't apply it casually. Always `terraform destroy`
when done experimenting; nothing here should be left running unattended.

## Repo layout

```
order-service/
├── src/
│   ├── api/          # REST API service
│   └── worker/       # background order processor
├── tests/            # unit/integration tests
├── scripts/           # bash automation (bootstrap, helpers)
├── docker/            # Dockerfiles + docker-compose
├── k8s/
│   ├── base/           # raw Kubernetes manifests
│   └── helm/            # Helm chart
├── terraform/
│   ├── modules/         # reusable infra modules
│   └── environments/    # dev / prod stacks (remote state per env)
├── .github/workflows/   # CI/CD pipelines
├── monitoring/
│   ├── dashboards/       # Grafana dashboard JSON
│   └── alerts/           # Prometheus alerting rules
└── docs/
    └── postmortems/      # incident write-ups from Phase 7
```
