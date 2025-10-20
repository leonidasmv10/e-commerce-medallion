# TechStore Analytics Platform

Plataforma de analítica de e-commerce que combina un pipeline de datos moderno con DBT + Databricks y una API REST para servir insights de negocio.

## Descripción del Proyecto

TechStore Analytics es una solución completa de datos que procesa información transaccional de un e-commerce y la transforma en insights accionables a través de:

- **Pipeline de Datos**: Arquitectura medallion (Bronze-Silver-Gold) implementada con DBT en Databricks
- **API REST**: FastAPI que expone endpoints para consultar métricas de clientes, productos y ventas
- **Analíticas Avanzadas**: Segmentación RFM, Customer Lifetime Value, métricas de productos y análisis de ventas

## Arquitectura del Sistema

### Visión General

```
┌─────────────────────────────────────────────────────────────────┐
│                        DATA SOURCES                              │
│                  (Databricks: techstore schema)                  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    DBT TRANSFORMATION PIPELINE                   │
│                   (techstore_databricks/techstore_dbt)          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐      ┌──────────────┐      ┌──────────────┐ │
│  │   BRONZE     │─────▶│    SILVER    │─────▶│     GOLD     │ │
│  │   (Raw)      │      │  (Cleaned)   │      │  (Metrics)   │ │
│  └──────────────┘      └──────────────┘      └──────────────┘ │
│   - customers           - customers           - customer_analytics│
│   - products            - products            - product_performance│
│   - orders              - orders              - sales_metrics    │
│   - order_items         - order_items         - operational_metrics│
│   - reviews             - reviews                                 │
│   - product_categories                                            │
└─────────────────────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                     DATABRICKS SQL WAREHOUSE                     │
│                  (Serving Layer - Delta Tables)                  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      FASTAPI REST API                            │
│                    (techstore_api/app)                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐ │
│  │   /api/customers │  │  /api/products   │  │  /api/sales  │ │
│  │                  │  │                  │  │              │ │
│  │ - Top Customers  │  │ - Best Sellers   │  │ - Summary    │ │
│  │ - By Segment     │  │ - Low Stock      │  │ - Trends     │ │
│  └──────────────────┘  └──────────────────┘  └──────────────┘ │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    CONSUMERS / DASHBOARDS                        │
│              (BI Tools, Apps, Data Science)                      │
└─────────────────────────────────────────────────────────────────┘
```

### Componentes Principales

#### 1. DBT Pipeline (`techstore_databricks/`)

**Arquitectura Medallion:**

- **Bronze Layer**: Ingesta raw de datos desde fuentes transaccionales
  - `bronze_customers`: Datos de clientes
  - `bronze_products`: Catálogo de productos
  - `bronze_orders`: Órdenes de compra
  - `bronze_order_items`: Líneas de pedido
  - `bronze_reviews`: Reseñas de productos
  - `bronze_product_categories`: Categorías

- **Silver Layer**: Limpieza, normalización y enriquecimiento
  - Estandarización de formatos (INITCAP, UPPER, LOWER)
  - Cálculos de antigüedad y tenencia
  - Validación de datos (NOT NULL constraints)
  - Clasificación de clientes por edad y lifetime stage

- **Gold Layer**: Modelos analíticos de negocio
  - `gold_customer_analytics`: Segmentación RFM, CLV, métricas por cliente
  - `gold_product_performance`: Performance de productos, inventario
  - `gold_sales_metrics`: Métricas diarias/mensuales, growth
  - `gold_operational_metrics`: KPIs operacionales

**Características Técnicas:**
- Materialización: Delta Tables en Databricks
- Formato: Delta Lake para ACID transactions
- Tags: Organización por layer y dominio
- Variables: Configuración centralizada (tax_rate, thresholds)

#### 2. FastAPI REST API (`techstore_api/`)

**Estructura:**
```
techstore_api/
├── app/
│   ├── main.py              # Aplicación principal FastAPI
│   ├── database/
│   │   └── connection.py    # Conexión a Databricks SQL
│   ├── models/
│   │   └── schemas.py       # Pydantic models para validación
│   └── routers/
│       ├── customers.py     # Endpoints de clientes
│       ├── products.py      # Endpoints de productos
│       └── sales.py         # Endpoints de ventas
```

**Características:**
- OpenAPI/Swagger documentation automática
- CORS configurado para acceso cross-origin
- Validación con Pydantic
- Connection pooling a Databricks
- Health check endpoint

#### 3. Databricks Integration

- Conexión vía Databricks SQL Connector
- Autenticación con Personal Access Token
- SQL Warehouse para queries de baja latencia
- Delta Lake para almacenamiento optimizado

## Instrucciones de Setup

### Prerrequisitos

- Python 3.12+
- Cuenta de Databricks con SQL Warehouse configurado
- Access Token de Databricks

### 1. Setup de DBT Pipeline

```bash
# Navegar al directorio de databricks
cd techstore_databricks

# Instalar dependencias (usando uv, o pip)
uv sync
# O con pip:
# pip install dbt-databricks>=1.10.12

# Configurar perfil de DBT (~/.dbt/profiles.yml)
# Crear archivo con la siguiente estructura:
```

**Archivo `~/.dbt/profiles.yml`:**
```yaml
techstore_dbt:
  target: dev
  outputs:
    dev:
      type: databricks
      catalog: workspace
      schema: techstore
      host: "{{ env_var('DBT_DATABRICKS_HOST') }}"
      http_path: "{{ env_var('DBT_DATABRICKS_HTTP_PATH') }}"
      token: "{{ env_var('DBT_DATABRICKS_TOKEN') }}"
      threads: 4
```

**Variables de entorno (alternativa):**
```bash
export DBT_DATABRICKS_HOST="<your-workspace>.databricks.com"
export DBT_DATABRICKS_HTTP_PATH="/sql/1.0/warehouses/xxxxx"
export DBT_DATABRICKS_TOKEN="dapi..."
```

**Ejecutar pipeline:**
```bash
cd techstore_dbt

# Verificar conexión
dbt debug

# Ejecutar transformaciones por layer
dbt run --select tag:bronze   # Bronze layer
dbt run --select tag:silver   # Silver layer
dbt run --select tag:gold     # Gold layer

# O ejecutar todo el pipeline
dbt run

# Ejecutar tests
dbt test
```

### 2. Setup de FastAPI

```bash
# Navegar al directorio de API
cd techstore_api

# Crear entorno virtual
python -m venv venv
source venv/bin/activate  # En Windows: venv\Scripts\activate

# Instalar dependencias
pip install fastapi uvicorn python-dotenv databricks-sql-connector pydantic

# Crear archivo .env
cat > .env << EOF
DBT_DATABRICKS_HOST=<your-workspace>.databricks.com
DBT_DATABRICKS_HTTP_PATH=/sql/1.0/warehouses/xxxxx
DBT_DATABRICKS_TOKEN=dapi...
EOF

# Ejecutar servidor
python -m app.main
```

### 3. Verificación

```bash
# Health check
curl http://localhost:8000/health

# Root endpoint
curl http://localhost:8000/

# Swagger UI
# Abrir en navegador: http://localhost:8000/docs
```

## Ejemplos de Uso de API

### Base URL
```
http://localhost:8000
```

### Endpoints Disponibles

#### 1. Customer Analytics

**GET `/api/customers/top-customers`**

Obtiene los clientes con mayor Customer Lifetime Value (CLV).

```bash
# Top 10 clientes (default)
curl http://localhost:8000/api/customers/top-customers

# Top 50 clientes
curl http://localhost:8000/api/customers/top-customers?limit=50
```

**Response:**
```json
[
  {
    "customer_id": 1234,
    "name": "John Doe",
    "email": "john.doe@example.com",
    "city": "New York",
    "country": "USA",
    "age_group": "35-44",
    "customer_lifetime_stage": "Veteran",
    "total_orders": 45,
    "total_revenue": 15000.50,
    "avg_order_value": 333.34,
    "customer_segment": "VIP",
    "customer_lifetime_value": 14955.50
  }
]
```

**GET `/api/customers/segments/{segment}`**

Filtra clientes por segmento RFM.

Segmentos válidos: `VIP`, `Loyal`, `New`, `At Risk`, `Lost`, `Regular`

```bash
# Clientes VIP
curl http://localhost:8000/api/customers/segments/VIP

# Clientes en riesgo
curl http://localhost:8000/api/customers/segments/At%20Risk?limit=100
```

#### 2. Product Performance

**GET `/api/products/best-sellers`**

Productos más vendidos con mejor performance.

```bash
curl http://localhost:8000/api/products/best-sellers?limit=20
```

**Response:**
```json
[
  {
    "product_id": 501,
    "product_name": "iPhone 15 Pro Max",
    "category": "Smartphones",
    "brand": "Apple",
    "current_price": 1199.99,
    "current_stock": 450,
    "total_units_sold": 3200,
    "total_revenue": 3839968.00,
    "total_profit": 768000.00,
    "sales_performance": "Best Seller",
    "avg_rating": 4.8,
    "product_health_score": 9.5
  }
]
```

**GET `/api/products/low-stock`**

Productos con stock bajo o crítico.

```bash
curl http://localhost:8000/api/products/low-stock
```

#### 3. Sales Metrics

**GET `/api/sales/summary`**

Resumen de ventas para un período específico.

```bash
# Últimos 30 días (default)
curl http://localhost:8000/api/sales/summary

# Últimos 90 días
curl http://localhost:8000/api/sales/summary?days=90

# Último año
curl http://localhost:8000/api/sales/summary?days=365
```

**Response:**
```json
{
  "days_analyzed": 30,
  "total_revenue": 450000.75,
  "total_orders": 1250,
  "avg_daily_revenue": 15000.02,
  "avg_order_value": 360.00
}
```

**GET `/api/sales/trends`**

Tendencias mensuales de ventas.

```bash
# Últimos 12 meses (default)
curl http://localhost:8000/api/sales/trends

# Últimos 24 meses
curl http://localhost:8000/api/sales/trends?months=24
```

**Response:**
```json
[
  {
    "sale_date": "2024-10-01T00:00:00",
    "daily_revenue": 525000.00,
    "daily_orders": 1450,
    "monthly_revenue": 525000.00,
    "mom_revenue_growth_percent": 12.5
  }
]
```

### Explorar API Interactivamente

FastAPI genera documentación interactiva automáticamente:

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **OpenAPI JSON**: http://localhost:8000/openapi.json

En Swagger UI puedes:
- Ver todos los endpoints disponibles
- Probar requests directamente desde el navegador
- Ver schemas de request/response
- Ver códigos de error

## Documentación Adicional

### API Documentation (Swagger/OpenAPI)

La documentación de la API se genera automáticamente con FastAPI:

```bash
# Iniciar servidor
python -m app.main

# Acceder a documentación
# Swagger UI: http://localhost:8000/docs
# ReDoc: http://localhost:8000/redoc
```

La documentación incluye:
- Descripción de todos los endpoints
- Parámetros de query con validaciones
- Modelos de request/response (Pydantic schemas)
- Ejemplos de uso
- Try-it-out functionality

### DBT Documentation

```bash
cd techstore_databricks/techstore_dbt

# Generar documentación
dbt docs generate

# Servir documentación (puerto 8080)
dbt docs serve

# Acceder en: http://localhost:8080
```

La documentación de DBT incluye:
- Lineage graph interactivo
- Descripciones de modelos
- Columnas y tipos de datos
- Dependencies entre modelos
- Tests ejecutados
- Metadata de ejecuciones

Flujo de datos resumido:

```
Sources (techstore schema)
    ↓
Bronze Layer (raw ingestion)
    ↓
Silver Layer (cleaning + enrichment)
    ↓
Gold Layer (business metrics)
    ↓
API Layer (FastAPI)
    ↓
Consumers (Apps, BI, Analytics)
```

## Tecnologías Utilizadas

| Categoría | Tecnología | Propósito |
|-----------|-----------|-----------|
| **Data Transformation** | DBT (Data Build Tool) | Transformaciones SQL modulares |
| **Data Platform** | Databricks | Lakehouse platform, SQL Warehouse |
| **Storage** | Delta Lake | ACID transactions, time travel |
| **API Framework** | FastAPI | REST API con validación automática |
| **API Validation** | Pydantic | Type validation, serialization |
| **Database Client** | databricks-sql-connector | Python SDK para Databricks SQL |
| **Server** | Uvicorn | ASGI server para FastAPI |
| **Package Manager** | uv / pip | Gestión de dependencias Python |

## Estructura del Proyecto

```
techstore/
├── README.md                          # Este archivo
├── DATA_LINEAGE.md                    # Documentación de flujo de datos
│
├── techstore_api/                     # FastAPI REST API
│   └── app/
│       ├── main.py                    # App principal
│       ├── database/
│       │   └── connection.py          # DB connection manager
│       ├── models/
│       │   └── schemas.py             # Pydantic models
│       └── routers/
│           ├── customers.py           # Customer endpoints
│           ├── products.py            # Product endpoints
│           └── sales.py               # Sales endpoints
│
└── techstore_databricks/              # DBT Pipeline
    ├── pyproject.toml                 # Project dependencies
    ├── main.py                        # Utility scripts
    └── techstore_dbt/                 # DBT project
        ├── dbt_project.yml            # DBT configuration
        ├── models/
        │   ├── bronze/                # Raw ingestion
        │   │   ├── sources.yml        # Source definitions
        │   │   ├── bronze_customers.sql
        │   │   ├── bronze_products.sql
        │   │   ├── bronze_orders.sql
        │   │   ├── bronze_order_items.sql
        │   │   ├── bronze_reviews.sql
        │   │   └── bronze_product_categories.sql
        │   │
        │   ├── silver/                # Cleaned data
        │   │   ├── silver_customers.sql
        │   │   ├── silver_products.sql
        │   │   ├── silver_orders.sql
        │   │   ├── silver_order_items.sql
        │   │   └── silver_reviews.sql
        │   │
        │   └── gold/                  # Business metrics
        │       ├── gold_customer_analytics.sql
        │       ├── gold_product_performance.sql
        │       ├── gold_sales_metrics.sql
        │       └── gold_operational_metrics.sql
        │
        ├── tests/                     # DBT tests
        ├── macros/                    # Reusable SQL macros
        ├── analyses/                  # Ad-hoc analyses
        └── seeds/                     # Static reference data
```

## Métricas y KPIs Disponibles

### Customer Analytics
- **RFM Segmentation**: Recency, Frequency, Monetary scores
- **Customer Segments**: VIP, Loyal, New, At Risk, Lost, Regular
- **CLV**: Customer Lifetime Value
- **Customer Tenure**: Lifetime stage (New, Recent, Regular, Veteran)
- **Age Groups**: Segmentación demográfica

### Product Performance
- **Sales Performance**: Best Seller, Good, Moderate, Poor
- **Stock Levels**: Critical, Low, Normal, Overstock, Out of Stock
- **Product Health Score**: Índice compuesto de performance
- **Revenue & Profit**: Total y por producto
- **Ratings**: Promedio de reseñas

### Sales Metrics
- **Daily/Monthly Revenue**: Ingresos agregados
- **AOV**: Average Order Value
- **MoM Growth**: Month-over-Month growth percentage
- **Order Volume**: Cantidad de órdenes
- **Customer Count**: Clientes únicos

---
