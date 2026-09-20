# Sausage Store

![image](https://user-images.githubusercontent.com/9394918/121517767-69db8a80-c9f8-11eb-835a-e98ca07fd995.png)


## Technologies used

* Frontend – TypeScript, Angular.
* Backend  – Java 16, Spring Boot, Spring Data.
* Database – H2.

## Installation guide
### Backend

Install Java 16 and maven and run:

```bash
cd backend
mvn package
cd target
java -jar sausage-store-0.0.1-SNAPSHOT.jar
```

### Frontend

Install NodeJS and npm on your computer and run:

```bash
cd frontend
npm install
npm run build
npm install -g http-server
sudo http-server ./dist/frontend/ -p 80 --proxy http://localhost:8080
```

Then open your browser and go to [http://localhost](http://localhost)

 
 
## Архитектура

Приложение состоит из четырёх сервисов и двух баз данных:

| Компонент | Технология | Назначение |
|-----------|-----------|-----------|
| **frontend** | Angular + Nginx | Пользовательский интерфейс |
| **backend** | Java Spring Boot | REST API, работа с заказами и товарами |
| **backend-report** | Go | Генерация отчётов |
| **PostgreSQL** | PostgreSQL 13.10 | Товары, заказы, связи заказов и товаров |
| **MongoDB** | MongoDB 7.0 | Отчёты пользовательской активности |

Взаимодействие:
- `frontend` → `backend` через Nginx-прокси `/api`.
- `backend` → `PostgreSQL` (JDBC).
- `backend` → `backend-report` через очередь отчётов.
- `backend-report` → `MongoDB` (по URI из Secret).
- `backend-report` получает заказы из `PostgreSQL` каждые 5 минут и сохраняет отчёты в `MongoDB`.

## Структура репозитория
.
├── .github/workflows/main.yaml # CI/CD пайплайн
├── backend/ # Java Spring Boot приложение
│ ├── src/main/resources/db/migration/ # Flyway-миграции V001–V005
│ └── Dockerfile
├── backend-report/ # Go-приложение
│ └── Dockerfile
├── frontend/ # Angular + Nginx
│ └── Dockerfile
└── sausage-store-chart/ # Helm-чарт
├── Chart.yaml
├── values.yaml
└── charts/
├── backend/
├── backend-report/
├── frontend/
└── infra/ # PostgreSQL + MongoDB

text

## Развёртывание

### Требования
- Кластер Kubernetes (в проекте — Yandex Managed Kubernetes).
- Настроенный `kubectl` (kubeconfig).
- Helm 3.

### Установка

```bash
# Создаём секрет для доступа к Docker Hub
kubectl create secret docker-registry regcred \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=<DOCKER_USER> \
  --docker-password=<DOCKER_PASSWORD> \
  --docker-email=<EMAIL> \
  -n <NAMESPACE>

# Устанавливаем чарт
helm install sausage-store ./sausage-store-chart -n <NAMESPACE>
После установки приложение доступно по адресу, указанному в values.yaml → frontend.ingress.host.

Helm-чарт
Ключевые параметры values.yaml
Параметр	Описание
frontend.image	Образ фронтенда
frontend.ingress.host	Домен для Ingress
backend.image	Образ бэкенда
backend.env.postgresUri	JDBC-подключение к PostgreSQL
backend-report.image	Образ backend-report
backend-report.secret.db	URI подключения к MongoDB
infra.postgresql.env	Креды PostgreSQL
infra.mongodb.env	Креды MongoDB
Особенности реализации
VPA для backend в режиме Off — только рекомендации по CPU/памяти.

HPA для backend-report — масштабирование по CPU, 1–5 реплик, target 75%.

LivenessProbe для backend на /actuator/health.

Стратегии деплоя: RollingUpdate для backend, Recreate для backend-report.

PVC для PostgreSQL и MongoDB — данные сохраняются между перезапусками.

MongoDB init job — Helm-хук, создающий пользователя reports при первой установке (идемпотентный, не затрагивает существующего пользователя).

CI/CD
Пайплайн .github/workflows/main.yaml запускается при пуше в main и состоит из трёх job-ов:

build_and_push_to_docker_hub — сборка и публикация трёх образов на Docker Hub.

add_helm_chart_to_nexus — упаковка Helm-чарта и загрузка в Nexus (hosted-репозиторий типа Helm).

deploy_helm_chart_to_kubernetes — деплой в кластер через helm upgrade --install из Nexus.

Секреты GitHub Actions
Секрет	Описание
DOCKER_USER	Логин Docker Hub
DOCKER_PASSWORD	Пароль или токен Docker Hub
KUBE_CONFIG	kubeconfig в base64
NEXUS_HELM_REPO	URL Helm-репозитория в Nexus
NEXUS_HELM_REPO_USER	Логин Nexus
NEXUS_HELM_REPO_PASSWORD	Пароль Nexus
Миграции БД
Flyway-миграции применяются автоматически при старте backend:

V001__create_tables.sql — базовая схема.

V002__change_schema.sql — нормализация схемы.

V003__insert_data.sql — тестовые данные (10 000 заказов).

V004__create_index.sql — индексы для отчётов.

V005__reset_sequences.sql — синхронизация sequence после bulk-insert.

Мониторинг
Backend экспортирует метрики Prometheus по /actuator/prometheus.

VPA рекомендует ресурсы на основе фактического потребления.

HPA автоматически масштабирует backend-report при росте нагрузки.
 