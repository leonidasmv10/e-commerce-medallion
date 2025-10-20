"""
TechStore Analytics API
FastAPI application to serve analytics data
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import customers, products, sales
from dotenv import load_dotenv
import uvicorn

# Load environment variables
load_dotenv()

# Create FastAPI app
app = FastAPI(
    title="TechStore Analytics API",
    description="""
## TechStore Analytics REST API

API para servir datos analíticos de e-commerce desde Databricks.

### Características

- **Customer Analytics**: Segmentación RFM, Customer Lifetime Value, métricas por cliente
- **Product Performance**: Best sellers, inventario, health scores
- **Sales Metrics**: Métricas diarias/mensuales, tendencias, crecimiento

### Arquitectura

Datos procesados con arquitectura Medallion (Bronze-Silver-Gold) usando DBT + Databricks Delta Lake.

### Autenticación

Currently public. Authentication will be added in future versions.

### Rate Limiting

No rate limiting currently applied. Use responsibly.

### Recursos Adicionales

- [Documentación completa](https://github.com/leonidasmv10/techstore)
- [DBT Docs](http://localhost:8080) (run `dbt docs serve`)
    """,
    version="1.0.0",
    contact={
        "name": "Leonidas",
        "email": "yordy.lmv.2000@gmail.com",
    },
    license_info={
        "name": "Proprietary",
    },
    openapi_tags=[
        {
            "name": "Customers",
            "description": "Customer analytics endpoints. Incluye segmentación RFM, CLV y métricas por cliente.",
        },
        {
            "name": "Products",
            "description": "Product performance endpoints. Analíticas de productos, inventario y health scores.",
        },
        {
            "name": "Sales",
            "description": "Sales metrics endpoints. Métricas de ventas diarias, mensuales y tendencias.",
        },
    ],
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(customers.router, prefix="/api/customers", tags=["Customers"])
app.include_router(products.router, prefix="/api/products", tags=["Products"])
app.include_router(sales.router, prefix="/api/sales", tags=["Sales"])

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "TechStore Analytics API",
        "version": "1.0.0",
        "endpoints": {
            "customers": "/api/customers",
            "products": "/api/products",
            "sales": "/api/sales"
        },
        "docs": "/docs"
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy"}

if __name__ == "__main__":
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)