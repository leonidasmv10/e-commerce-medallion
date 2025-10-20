"""
Pydantic schemas for API request/response models
"""

from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from decimal import Decimal

class CustomerAnalytics(BaseModel):
    customer_id: int
    name: str
    email: str
    city: Optional[str] = None
    country: Optional[str] = None
    age_group: Optional[str] = None
    customer_lifetime_stage: Optional[str] = None
    total_orders: int
    total_revenue: Decimal
    avg_order_value: Decimal
    customer_segment: Optional[str] = None
    customer_lifetime_value: Optional[Decimal] = None
    
    class Config:
        from_attributes = True

class ProductPerformance(BaseModel):
    product_id: int
    product_name: str
    category: str
    brand: str
    current_price: Decimal
    current_stock: int
    total_units_sold: int
    total_revenue: Decimal
    total_profit: Decimal
    sales_performance: str
    avg_rating: Decimal
    product_health_score: Decimal
    
    class Config:
        from_attributes = True

class SalesSummary(BaseModel):
    sale_date: Optional[datetime] = None
    daily_revenue: Optional[Decimal] = None
    daily_orders: Optional[int] = None
    monthly_revenue: Optional[Decimal] = None
    mom_revenue_growth_percent: Optional[Decimal] = None
    
    class Config:
        from_attributes = True