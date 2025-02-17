"""API data models and enums."""

from enum import Enum
from typing import Any, Dict, List, Optional, Union

from pydantic import BaseModel, Field, model_validator, validator


class DataLoadStrategy(Enum):
    """Available strategies for loading data into database."""
    SQLALCHEMY = "sqlalchemy"  # Using SQLAlchemy ORM
    PYODBC_FAST = "pyodbc_fast"  # Using pyodbc fast_executemany
    EXTERNAL_TABLE = "external_table"  # Using external tables (Netezza)

class SQLSource(BaseModel):
    """SQL source for graph data."""
    type: str = "sql"
    dsn: str = Field(..., description="Database connection string")
    vertex_sql: str = Field(..., description="SQL query for vertex data")
    edge_sql: str = Field(..., description="SQL query for edge data")

class FileSource(BaseModel):
    """
    File data source configuration.
    Can accept either file paths or direct data input.
    """
    type: str = "file"
    vertex_file: Optional[str] = None
    edge_file: Optional[str] = None
    vertex_data: Optional[List[Dict[str, Any]]] = None
    edge_data: Optional[List[Dict[str, Any]]] = None

    @validator("type")
    def validate_type(cls, v):
        if v != "file":
            raise ValueError("Type must be 'file'")
        return v
    
    @model_validator(mode='after')
    def validate_data_source(self) -> 'FileSource':
        has_files = self.vertex_file is not None and self.edge_file is not None
        has_data = self.vertex_data is not None and self.edge_data is not None
        
        if not (has_files or has_data):
            raise ValueError("Must provide either file paths (vertex_file, edge_file) or direct data (vertex_data, edge_data)")
        
        if has_files and has_data:
            raise ValueError("Cannot provide both file paths and direct data")
            
        return self

class GraphRequest(BaseModel):
    """Request model for graph processing."""
    source: Union[SQLSource, FileSource] = Field(..., description="Data source configuration")
    format: str = Field("json", description="Output format (json, csv, d3, or networkx)")
    node_id: Optional[str] = Field(None, description="Root node ID for subgraph extraction")
    params: Optional[Dict[str, Any]] = Field(default_factory=dict, description="Additional parameters for graph processing")

    class Config:
        use_enum_values = True

class GraphResponse(BaseModel):
    """Base response model for graph data."""
    nodes: List[Dict]
    links: List[Dict]
    metrics: Optional[Dict] = None 