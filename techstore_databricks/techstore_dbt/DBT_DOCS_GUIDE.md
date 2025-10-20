# DBT Documentation Guide

Esta guía explica cómo generar, servir y utilizar la documentación de DBT para el proyecto TechStore Analytics.

## Tabla de Contenidos

- [Qué es DBT Docs](#qué-es-dbt-docs)
- [Generar Documentación](#generar-documentación)
- [Servir Documentación](#servir-documentación)
- [Navegación de la Interfaz](#navegación-de-la-interfaz)
- [Lineage Graph](#lineage-graph)
- [Explorar Modelos](#explorar-modelos)
- [Búsqueda y Filtros](#búsqueda-y-filtros)
- [Artifacts Generados](#artifacts-generados)

## Qué es DBT Docs

DBT Docs es una interfaz web interactiva que proporciona:

- **Lineage Graph**: Visualización del DAG (Directed Acyclic Graph) completo
- **Model Documentation**: Descripciones detalladas de cada modelo
- **Column Details**: Tipos de datos, descripciones y tests por columna
- **Source Tracking**: Origen de los datos
- **Test Results**: Estado de validaciones de calidad
- **Dependencies**: Relaciones entre modelos (upstream/downstream)
- **Code Viewer**: SQL compilado y raw de cada modelo

## Generar Documentación

### Comando Básico

```bash
# Navegar al proyecto DBT
cd techstore_databricks/techstore_dbt

# Generar documentación
dbt docs generate
```

### Output Esperado

```
Running with dbt=1.x.x
Found X models, Y tests, Z sources

Concurrency: 4 threads

Building catalog
Catalog written to target/catalog.json
Documentation written to target/manifest.json
```

### Archivos Generados

La documentación se genera en el directorio `target/`:

```
target/
├── manifest.json           # DAG completo, dependencies, metadata
├── catalog.json           # Table/column metadata from warehouse
├── run_results.json       # Last execution results
├── graph.gpickle         # Graph data structure
└── compiled/             # Compiled SQL queries
```

## Servir Documentación

### Comando Local

```bash
# Servir en puerto 8080 (default)
dbt docs serve

# Servir en puerto custom
dbt docs serve --port 8888
```

### Acceder a la Interfaz

Abrir en navegador:
```
http://localhost:8080
```

### Opciones Avanzadas

```bash
# Generar y servir en un comando
dbt docs generate && dbt docs serve

# Servir sin abrir navegador automáticamente
dbt docs serve --no-browser

# Especificar host
dbt docs serve --host 0.0.0.0 --port 8080
```

## Navegación de la Interfaz

### Panel Principal

La interfaz de DBT Docs se divide en:

1. **Left Sidebar**: Navegación de proyectos y modelos
2. **Main Panel**: Vista de detalles del modelo seleccionado
3. **Lineage Graph**: Visualización de dependencias
4. **Search Bar**: Búsqueda global

### Secciones Principales

#### Project (Inicio)

- **Overview**: Descripción general del proyecto
- **Database**: Información de conexión
- **Models**: Lista de todos los modelos
- **Sources**: Fuentes de datos
- **Tests**: Tests de calidad definidos

#### Models (Modelos)

Organizado por carpetas:
```
├── bronze/
│   ├── bronze_customers
│   ├── bronze_products
│   ├── bronze_orders
│   └── ...
├── silver/
│   ├── silver_customers
│   ├── silver_products
│   └── ...
└── gold/
    ├── gold_customer_analytics
    ├── gold_product_performance
    └── ...
```

## Lineage Graph

### Acceder al Graph

1. Hacer click en cualquier modelo
2. Presionar el botón "View Lineage Graph" (icono de grafo)
3. O presionar `g` en el teclado

### Características del Graph

**Navegación:**
- Zoom: Scroll del mouse o pinch
- Pan: Click y arrastrar
- Center: Doble click en background
- Focus: Click en un nodo

**Colores:**
- **Verde**: Sources (fuentes externas)
- **Azul**: Models (transformaciones DBT)
- **Gris**: Seeds (datos estáticos)
- **Naranja**: Snapshots

**Filtros:**
- `--select`: Mostrar solo modelos seleccionados
- `--exclude`: Excluir modelos
- Upstream: `+model_name` (padres)
- Downstream: `model_name+` (hijos)

### Ejemplos de Lineage

**Ver todo el flujo de customers:**
```
Click en "gold_customer_analytics" → View Lineage Graph
```

Verás:
```
techstore.customers (source)
    ↓
bronze_customers
    ↓
silver_customers
    ↓
gold_customer_analytics
```

**Ver dependencias de productos:**
```
Click en "gold_product_performance" → View Lineage Graph
```

Mostrará múltiples upstream dependencies:
- `silver_products`
- `silver_order_items`
- `silver_reviews`

## Explorar Modelos

### Vista de Modelo Individual

Al hacer click en un modelo (ej: `gold_customer_analytics`), verás:

#### 1. Description Tab

**Descripción del Modelo:**
- Propósito y use cases
- Lógica de negocio
- Transformaciones aplicadas
- Algoritmos (ej: RFM, CLV)

**Ejemplo para gold_customer_analytics:**
```
Comprehensive customer analytics model with RFM segmentation and CLV.

RFM Analysis:
- Recency: Days since last order
- Frequency: Total number of orders
- Monetary: Total revenue generated
...
```

#### 2. Columns Tab

**Información por Columna:**

| Column Name | Type | Description | Tests |
|-------------|------|-------------|-------|
| customer_id | BIGINT | Customer unique identifier | unique, not_null |
| customer_segment | STRING | RFM-based segment | - |
| customer_lifetime_value | DECIMAL | Estimated CLV in dollars | - |

**Detalles Incluidos:**
- Nombre de columna
- Tipo de dato (from warehouse)
- Descripción (from schema.yml)
- Tests aplicados
- Constraints

#### 3. Code Tab

**Raw SQL:**
Muestra el código fuente original del modelo.

```sql
{{
    config(
        materialized='table',
        tags=['gold', 'customer_analytics']
    )
}}

WITH customer_orders AS (
    SELECT
        o.customer_id,
        COUNT(DISTINCT o.id) as total_orders,
        ...
```

**Compiled SQL:**
Muestra el SQL compilado después de que Jinja resuelva las macros y refs.

```sql
-- Compiled version (refs resolved to actual table names)
WITH customer_orders AS (
    SELECT
        o.customer_id,
        COUNT(DISTINCT o.id) as total_orders,
        SUM(o.total_amount) as total_revenue,
        ...
    FROM workspace.techstore.silver_orders o
    ...
```

#### 4. Details Tab

**Metadata del Modelo:**
- Database: `workspace`
- Schema: `techstore`
- Name: `gold_customer_analytics`
- Package: `techstore_analytics`
- Materialization: `table`
- Tags: `gold`, `customer_analytics`
- File path: `models/gold/gold_customer_analytics.sql`

**Depends On:**
Lista de modelos upstream (padres):
- `silver_customers`
- `silver_orders`

**Referenced By:**
Modelos downstream que dependen de este modelo (si existen).

## Búsqueda y Filtros

### Búsqueda Global

**Search Bar (top right):**
- Buscar por nombre de modelo
- Buscar por descripción
- Buscar por tag
- Buscar por columna

**Ejemplos:**
```
"customer"        → Encuentra todos los modelos relacionados con customers
"tag:gold"        → Filtra solo modelos gold
"CLV"             → Busca en descripciones
"email"           → Encuentra columnas llamadas email
```

### Filtros por Tag

En la sidebar izquierda, filtrar por tags:
- `bronze` - Todos los modelos bronze
- `silver` - Todos los modelos silver
- `gold` - Todos los modelos gold
- `customer_analytics` - Modelos de analítica de clientes
- `sales_metrics` - Modelos de métricas de ventas

### Navegación por Carpeta

Expandir/colapsar carpetas en el tree view:
```
📁 models
  📁 bronze
    📄 bronze_customers
    📄 bronze_products
  📁 silver
    📄 silver_customers
  📁 gold
    📄 gold_customer_analytics
```

## Artifacts Generados

### manifest.json

**Contenido:**
- Definiciones completas de todos los modelos
- DAG de dependencias
- Tests configurados
- Macros y variables
- Source definitions

**Uso:**
```json
{
  "nodes": {
    "model.techstore_analytics.gold_customer_analytics": {
      "database": "workspace",
      "schema": "techstore",
      "name": "gold_customer_analytics",
      "depends_on": {
        "nodes": [
          "model.techstore_analytics.silver_customers",
          "model.techstore_analytics.silver_orders"
        ]
      },
      ...
    }
  }
}
```

### catalog.json

**Contenido:**
- Metadata de tablas reales en warehouse
- Column names y types (from database)
- Row counts
- Table sizes
- Last modified timestamps

**Uso:**
- Validar que modelos existen en warehouse
- Verificar tipos de datos
- Auditar freshness

### run_results.json

**Contenido:**
- Resultados de última ejecución
- Timing por modelo
- Success/failure status
- Error messages (si hay)

**Ejemplo:**
```json
{
  "results": [
    {
      "unique_id": "model.techstore_analytics.gold_customer_analytics",
      "status": "success",
      "execution_time": 12.34,
      "rows_affected": 5000
    }
  ]
}
```

## Mejores Prácticas

### 1. Mantener Documentación Actualizada

Agregar descripciones en `schema.yml`:

```yaml
models:
  - name: gold_customer_analytics
    description: |
      Customer analytics with RFM segmentation.

      Use cases:
      - Marketing segmentation
      - Churn prediction
      - CLV optimization
    columns:
      - name: customer_id
        description: Unique customer identifier
        tests:
          - unique
          - not_null
```

### 2. Usar Tags Consistentemente

```yaml
{{
    config(
        materialized='table',
        tags=['gold', 'customer_analytics', 'daily_refresh']
    )
}}
```

### 3. Documentar Lógica de Negocio

Incluir fórmulas y decisiones:

```yaml
- name: customer_lifetime_value
  description: |
    CLV = (Average Order Value × Total Orders) - Acquisition Cost

    Assumptions:
    - Acquisition cost: $50 flat rate
    - Only counts delivered/shipped orders
    - Excludes refunds
```

### 4. Regenerar Regularmente

```bash
# Después de cada cambio importante
dbt run
dbt test
dbt docs generate
```

## Compartir Documentación

### Opción 1: Local Access

```bash
# Miembros del equipo acceden localmente
dbt docs serve --host 0.0.0.0 --port 8080
# Acceder desde: http://<your-ip>:8080
```

### Opción 2: Static Site Hosting

```bash
# Generar docs
dbt docs generate

# Copiar archivos a hosting (S3, GCS, Azure, etc)
aws s3 sync target/ s3://your-bucket/dbt-docs/

# O usar dbt Cloud (automated)
```

### Opción 3: DBT Cloud

DBT Cloud proporciona hosting automático de docs:
- Auto-regeneración después de cada run
- Control de acceso
- Versionado

## Troubleshooting

### Docs no se generan

```bash
# Error: Could not connect to database
# Solución: Verificar profiles.yml y credenciales
dbt debug

# Error: No models found
# Solución: Verificar dbt_project.yml y model-paths
```

### Graph no muestra correctamente

```bash
# Limpiar cache y regenerar
dbt clean
dbt compile
dbt docs generate
```

### Columnas faltantes en catalog

```bash
# Catalog solo incluye tablas que existen en warehouse
# Ejecutar modelos primero:
dbt run
dbt docs generate
```

## Recursos Adicionales

- [DBT Docs Official Guide](https://docs.getdbt.com/docs/collaborate/documentation)
- [Schema.yml Reference](https://docs.getdbt.com/reference/configs-and-properties)
- [DBT Cloud Docs](https://docs.getdbt.com/docs/dbt-cloud/cloud-overview)

---

**Última actualización**: 2025-10-20

**Comandos Quick Reference:**
```bash
# Generar y servir docs
dbt docs generate && dbt docs serve

# Acceder
http://localhost:8080

# Ver lineage
Click en modelo → "g" key → Lineage graph
```
