"""
Product performance endpoints
"""

from fastapi import APIRouter, HTTPException, Query
from typing import List
from app.models.schemas import ProductPerformance
from app.database.connection import db

router = APIRouter()

@router.get("/best-sellers", response_model=List[ProductPerformance])
async def get_best_sellers(
    limit: int = Query(10, ge=1, le=100)
):
    """
    Obtiene los productos con mejor performance de ventas.

    Incluye productos clasificados como "Best Seller" o "Good" basado en:
    - Total revenue generado
    - Unidades vendidas
    - Product health score (composite metric)
    - Average rating

    **Parámetros:**
    - **limit**: Número de productos (1-100, default: 10)

    **Returns:**
    Productos ordenados por revenue total descendente, incluyendo:
    - Métricas de ventas (revenue, profit, units sold)
    - Estado de inventario
    - Ratings promedio
    - Product health score

    **Ejemplo:**
    ```
    GET /api/products/best-sellers?limit=25
    ```
    """
    query = """
        SELECT 
            product_id, product_name, category, brand, current_price,
            current_stock, total_units_sold, total_revenue, total_profit,
            sales_performance, avg_rating, product_health_score
        FROM workspace.techstore.gold_product_performance
        WHERE sales_performance IN ('Best Seller', 'Good')
        ORDER BY total_revenue DESC
        LIMIT {limit}
    """.format(limit=limit)
    
    try:
        results = db.execute_query(query)
        return results
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

@router.get("/low-stock", response_model=List[ProductPerformance])
async def get_low_stock():
    """
    Obtiene productos con inventario bajo o crítico.

    **Niveles de stock incluidos:**
    - **Out of Stock**: 0 unidades
    - **Critical**: < 10 unidades
    - **Low**: 10-50 unidades

    Útil para:
    - Alertas de reabastecimiento
    - Planificación de compras
    - Prevención de stockouts

    **Returns:**
    Hasta 50 productos ordenados por stock ascendente (más crítico primero)

    **Ejemplo:**
    ```
    GET /api/products/low-stock
    ```
    """
    query = """
        SELECT 
            product_id, product_name, category, brand, current_price,
            current_stock, total_units_sold, total_revenue, total_profit,
            sales_performance, avg_rating, product_health_score
        FROM workspace.techstore.gold_product_performance
        WHERE stock_level IN ('Critical', 'Low', 'Out of Stock')
        ORDER BY current_stock ASC
        LIMIT 50
    """
    
    try:
        results = db.execute_query(query)
        return results
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")