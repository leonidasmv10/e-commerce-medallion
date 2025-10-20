"""
Sales metrics endpoints
"""

from fastapi import APIRouter, HTTPException, Query
from typing import List
from app.models.schemas import SalesSummary
from app.database.connection import db

router = APIRouter()

@router.get("/summary")
async def get_sales_summary(days: int = Query(30, ge=1, le=365)):
    """
    Obtiene resumen agregado de ventas para un período específico.

    **Métricas calculadas:**
    - Total revenue del período
    - Total de órdenes
    - Revenue diario promedio
    - Average Order Value (AOV)
    - Días analizados

    **Parámetros:**
    - **days**: Días hacia atrás desde hoy (1-365, default: 30)

    **Use cases:**
    - KPI dashboards
    - Reportes ejecutivos
    - Comparación de períodos

    **Ejemplo:**
    ```
    GET /api/sales/summary?days=90
    ```
    """
    query = """
        SELECT
            COUNT(DISTINCT sale_date) as days_analyzed,
            SUM(daily_revenue) as total_revenue,
            SUM(daily_orders) as total_orders,
            AVG(daily_revenue) as avg_daily_revenue,
            AVG(daily_aov) as avg_order_value
        FROM workspace.techstore.gold_sales_metrics
        WHERE sale_date >= DATE_SUB(CURRENT_DATE(), {days})
    """.format(days=days)
    
    try:
        result = db.execute_query_single(query)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

@router.get("/trends", response_model=List[SalesSummary])
async def get_sales_trends(months: int = Query(12, ge=1, le=24)):
    """
    Obtiene tendencias de ventas mensuales con métricas de crecimiento.

    **Métricas incluidas:**
    - Revenue mensual
    - Órdenes mensuales
    - Clientes únicos
    - Month-over-Month (MoM) revenue growth %

    **Parámetros:**
    - **months**: Meses hacia atrás (1-24, default: 12)

    **Returns:**
    Series temporal ordenada del más reciente al más antiguo

    **Use cases:**
    - Análisis de tendencias
    - Forecasting
    - Detección de estacionalidad
    - Tracking de crecimiento

    **Ejemplo:**
    ```
    GET /api/sales/trends?months=18
    ```
    """
    query = """
        SELECT DISTINCT
            month_start as sale_date,
            monthly_revenue as daily_revenue,
            monthly_orders as daily_orders,
            monthly_revenue,
            mom_revenue_growth_percent
        FROM workspace.techstore.gold_sales_metrics
        WHERE month_start IS NOT NULL
        ORDER BY month_start DESC
        LIMIT {months}
    """.format(months=months)
    
    try:
        results = db.execute_query(query)
        return results
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")