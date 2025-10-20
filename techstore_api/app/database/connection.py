"""
Database connection management for Databricks
"""

from databricks import sql
import os
from typing import List, Dict, Any
from contextlib import contextmanager

class DatabricksConnection:
    """Manages connections to Databricks SQL warehouse"""
    
    def __init__(self):
        self.server_hostname = os.getenv("DBT_DATABRICKS_HOST")
        self.http_path = os.getenv("DBT_DATABRICKS_HTTP_PATH")
        self.access_token = os.getenv("DBT_DATABRICKS_TOKEN")
        
        if not all([self.server_hostname, self.http_path, self.access_token]):
            raise ValueError("Missing required Databricks environment variables")
    
    @contextmanager
    def get_connection(self):
        """Context manager for database connections"""
        connection = sql.connect(
            server_hostname=self.server_hostname,
            http_path=self.http_path,
            access_token=self.access_token
        )
        try:
            yield connection
        finally:
            connection.close()
    
    def execute_query(self, query: str, params: Dict[str, Any] = None) -> List[Dict[str, Any]]:
        """Execute a query and return results as list of dictionaries"""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            
            if params:
                cursor.execute(query, params)
            else:
                cursor.execute(query)
            
            columns = [desc[0] for desc in cursor.description]
            
            results = []
            for row in cursor.fetchall():
                results.append(dict(zip(columns, row)))
            
            cursor.close()
            return results
    
    def execute_query_single(self, query: str, params: Dict[str, Any] = None) -> Dict[str, Any]:
        """Execute a query and return single result"""
        results = self.execute_query(query, params)
        return results[0] if results else None

# Create singleton instance
db = DatabricksConnection()