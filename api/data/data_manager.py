"""Database operations and connection management module."""

import os
from contextlib import contextmanager
from enum import Enum
from pathlib import Path
from typing import Any, Dict, Generator, List, Optional, Union

import pandas as pd
import pyodbc
from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine
from sqlalchemy.pool import QueuePool

from api.data.models import DataLoadStrategy


class ConnectionManager:
    """Manages database connections with connection pooling."""
    
    def __init__(self):
        self._current_dsn: Optional[str] = None
        self._engine: Optional[Engine] = None
        self._conn_pool: Dict[str, pyodbc.Connection] = {}
    
    def set_connection(self, dsn: str) -> None:
        """Set the current connection DSN."""
        if dsn != self._current_dsn:
            self._current_dsn = dsn
            self._engine = create_engine(
                f"mssql+pyodbc:///?odbc_connect={dsn}",
                poolclass=QueuePool,
                pool_size=5,
                max_overflow=10
            )
    
    @contextmanager
    def get_connection(self, dsn: Optional[str] = None) -> Generator[pyodbc.Connection, None, None]:
        """Get a connection from the pool or create a new one."""
        use_dsn = dsn or self._current_dsn
        if not use_dsn:
            raise ValueError("No DSN provided and no current connection set")
            
        if use_dsn not in self._conn_pool:
            self._conn_pool[use_dsn] = pyodbc.connect(use_dsn)
            
        try:
            yield self._conn_pool[use_dsn]
        except pyodbc.Error as e:
            # If connection is dead, remove it from pool
            if "Connection is closed" in str(e):
                del self._conn_pool[use_dsn]
            raise

class DataManager:
    """Handles database operations and data loading."""
    
    def __init__(self):
        self._conn_manager = ConnectionManager()
        self.temp_dir = Path("temp")
        self.temp_dir.mkdir(exist_ok=True)
    
    def set_connection(self, dsn: str) -> None:
        """Set the current database connection."""
        self._conn_manager.set_connection(dsn)
    
    def execute_query(self, sql: str, params: Optional[Dict[str, Any]] = None) -> pd.DataFrame:
        """Execute SQL query and return results as DataFrame."""
        with self._conn_manager.get_connection() as conn:
            cursor = conn.cursor()
            if params:
                cursor.execute(sql, params)
            else:
                cursor.execute(sql)
            results = cursor.fetchall()
            columns = [column[0] for column in cursor.description]
            return pd.DataFrame.from_records(results, columns=columns)
    
    def execute_sql(self, sql: str, params: Optional[Dict[str, Any]] = None) -> None:
        """Execute SQL command without returning results."""
        with self._conn_manager.get_connection() as conn:
            cursor = conn.cursor()
            if params:
                cursor.execute(sql, params)
            else:
                cursor.execute(sql)
            conn.commit()
    
    def save_to_database(
        self,
        df: pd.DataFrame,
        table_name: str,
        schema: str = "dbo",
        strategy: DataLoadStrategy = DataLoadStrategy.SQLALCHEMY,
        if_exists: str = "fail",
        batch_size: int = 1000,
        **kwargs
    ) -> None:
        """
        Save DataFrame to database using specified strategy.
        
        Args:
            df: DataFrame to save
            table_name: Target table name
            schema: Database schema
            strategy: Data loading strategy to use
            if_exists: How to behave if table exists ('fail', 'replace', 'append')
            batch_size: Batch size for bulk operations
            **kwargs: Additional strategy-specific arguments
        """
        if strategy == DataLoadStrategy.SQLALCHEMY:
            self._save_sqlalchemy(df, table_name, schema, if_exists)
        elif strategy == DataLoadStrategy.PYODBC_FAST:
            self._save_pyodbc_fast(df, table_name, schema, if_exists, batch_size)
        elif strategy == DataLoadStrategy.EXTERNAL_TABLE:
            self._save_external_table(df, table_name, schema, if_exists, **kwargs)
        else:
            raise ValueError(f"Unknown strategy: {strategy}")
    
    def _save_sqlalchemy(
        self,
        df: pd.DataFrame,
        table_name: str,
        schema: str,
        if_exists: str
    ) -> None:
        """Save using SQLAlchemy."""
        if not self._conn_manager._engine:
            raise ValueError("No SQLAlchemy engine available. Call set_connection first.")
            
        df.to_sql(
            name=table_name,
            schema=schema,
            con=self._conn_manager._engine,
            if_exists=if_exists,
            index=False
        )
    
    def _save_pyodbc_fast(
        self,
        df: pd.DataFrame,
        table_name: str,
        schema: str,
        if_exists: str,
        batch_size: int
    ) -> None:
        """Save using pyodbc fast_executemany."""
        with self._conn_manager.get_connection() as conn:
            cursor = conn.cursor()
            
            # Create table if needed
            if if_exists == "replace":
                cursor.execute(f"DROP TABLE IF EXISTS {schema}.{table_name}")
                
            if if_exists in ["replace", "fail"]:
                create_stmt = self._get_create_table_stmt(df, table_name, schema)
                cursor.execute(create_stmt)
            
            # Prepare insert statement
            columns = df.columns.tolist()
            placeholders = ",".join("?" * len(columns))
            insert_stmt = f"INSERT INTO {schema}.{table_name} ({','.join(columns)}) VALUES ({placeholders})"
            
            # Execute in batches
            cursor.fast_executemany = True
            for i in range(0, len(df), batch_size):
                batch = df.iloc[i:i + batch_size]
                cursor.executemany(insert_stmt, batch.values.tolist())
            
            conn.commit()
    
    def _save_external_table(
        self,
        df: pd.DataFrame,
        table_name: str,
        schema: str,
        if_exists: str,
        delimiter: str = ",",
        external_schema: str = "ext",
        external_location: str = "/tmp/external_tables",
        **kwargs
    ) -> None:
        """Save using Netezza external table approach."""
        # Save to temporary CSV
        temp_file = self.temp_dir / f"{table_name}_temp.csv"
        df.to_csv(temp_file, index=False, sep=delimiter)
        
        try:
            with self._conn_manager.get_connection() as conn:
                cursor = conn.cursor()
                
                # Create external schema if not exists
                cursor.execute(f"CREATE SCHEMA IF NOT EXISTS {external_schema}")
                
                # Create external table
                ext_table_name = f"{table_name}_ext"
                create_ext_stmt = f"""
                CREATE EXTERNAL TABLE {external_schema}.{ext_table_name} (
                    {self._get_column_definitions(df)}
                )
                USING (
                    DATAOBJECT ('{temp_file}')
                    DELIMITER '{delimiter}'
                    SKIPROWS 1
                )
                """
                cursor.execute(create_ext_stmt)
                
                # Create and populate actual table
                if if_exists == "replace":
                    cursor.execute(f"DROP TABLE IF EXISTS {schema}.{table_name}")
                
                create_stmt = self._get_create_table_stmt(df, table_name, schema)
                cursor.execute(create_stmt)
                
                # Insert data from external table
                cursor.execute(f"""
                INSERT INTO {schema}.{table_name}
                SELECT * FROM {external_schema}.{ext_table_name}
                """)
                
                # Cleanup
                cursor.execute(f"DROP EXTERNAL TABLE {external_schema}.{ext_table_name}")
                conn.commit()
                
        finally:
            # Clean up temporary file
            if temp_file.exists():
                temp_file.unlink()
    
    def _get_create_table_stmt(self, df: pd.DataFrame, table_name: str, schema: str) -> str:
        """Generate CREATE TABLE statement from DataFrame."""
        return f"""
        CREATE TABLE {schema}.{table_name} (
            {self._get_column_definitions(df)}
        )
        """
    
    def _get_column_definitions(self, df: pd.DataFrame) -> str:
        """Generate column definitions from DataFrame."""
        type_mapping = {
            "object": "VARCHAR(255)",
            "int64": "BIGINT",
            "float64": "DOUBLE PRECISION",
            "bool": "BOOLEAN",
            "datetime64[ns]": "TIMESTAMP"
        }
        
        definitions = []
        for col in df.columns:
            dtype = str(df[col].dtype)
            sql_type = type_mapping.get(dtype, "VARCHAR(255)")
            definitions.append(f"{col} {sql_type}")
            
        return ",\n".join(definitions)
    
    def cleanup(self) -> None:
        """Clean up resources."""
        # Close all connections in pool
        for conn in self._conn_manager._conn_pool.values():
            try:
                conn.close()
            except:
                pass
        self._conn_manager._conn_pool.clear()
        
        # Remove temporary directory if empty
        try:
            self.temp_dir.rmdir()
        except:
            pass 