"""
Customer analytics endpoints
"""

from fastapi import APIRouter, HTTPException, Query
from typing import List
from app.models.schemas import CustomerAnalytics
from app.database.connection import db

router = APIRouter()

@router.get("/top-customers", response_model=List[CustomerAnalytics])
async def get_top_customers(
    limit: int = Query(10, ge=1, le=100, description="Number of top customers")
):
    """
    Obtiene los mejores clientes ordenados por Customer Lifetime Value (CLV).

    El CLV se calcula como: (Valor promedio de orden × Total de órdenes) - Costo de adquisición

    **Parámetros:**
    - **limit**: Número de clientes a retornar (1-100, default: 10)

    **Returns:**
    Lista de clientes con métricas completas incluyendo:
    - Segmentación RFM (Recency, Frequency, Monetary)
    - Customer Lifetime Value
    - Total de órdenes y revenue
    - Segment classification (VIP, Loyal, New, At Risk, Lost, Regular)

    **Ejemplo de uso:**
    ```
    GET /api/customers/top-customers?limit=20
    ```
    """
    query = """
        SELECT 
            customer_id, name, email, city, country, age_group,
            customer_lifetime_stage, total_orders, total_revenue,
            avg_order_value, customer_segment, customer_lifetime_value
        FROM workspace.techstore.gold_customer_analytics
        ORDER BY customer_lifetime_value DESC
        LIMIT {limit}
    """.format(limit=limit)
    
    try:
        results = db.execute_query(query)
        return results
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

@router.get("/segments/{segment}", response_model=List[CustomerAnalytics])
async def get_customers_by_segment(
    segment: str,
    limit: int = Query(50, ge=1, le=200)
):
    """
    Obtiene clientes filtrados por segmento RFM.

    **Segmentos disponibles:**
    - **VIP**: Alta recencia, frecuencia y valor monetario (R≥4, F≥4, M≥4)
    - **Loyal**: Buenos scores en todas las dimensiones (R≥3, F≥3, M≥3)
    - **New**: Compra reciente pero baja frecuencia (R≥4, F=1)
    - **At Risk**: No compran recientemente pero tienen historial (R≤2, F≥2)
    - **Lost**: Baja recencia y frecuencia (R≤2, F≤2)
    - **Regular**: Clientes con comportamiento moderado

    **Parámetros:**
    - **segment**: Nombre del segmento (case-sensitive)
    - **limit**: Número máximo de resultados (1-200, default: 50)

    **Ejemplo de uso:**
    ```
    GET /api/customers/segments/VIP?limit=100
    GET /api/customers/segments/At%20Risk
    ```
    """
    valid_segments = ["VIP", "Loyal", "New", "At Risk", "Lost", "Regular"]
    
    if segment not in valid_segments:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid segment. Must be one of: {', '.join(valid_segments)}"
        )
    
    query = """
        SELECT 
            customer_id, name, email, city, country, age_group,
            customer_lifetime_stage, total_orders, total_revenue,
            avg_order_value, customer_segment, customer_lifetime_value
        FROM workspace.techstore.gold_customer_analytics
        WHERE customer_segment = '{segment}'
        ORDER BY customer_lifetime_value DESC
        LIMIT {limit}
    """.format(segment=segment, limit=limit)
    
    try:
        results = db.execute_query(query)
        return results
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")