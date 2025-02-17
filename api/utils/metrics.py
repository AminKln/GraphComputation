"""API metrics tracking system."""

import atexit
import json
import threading
import time
from collections import Counter, defaultdict
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional, Set

import pandas as pd

from ..config.settings import BASE_DIR

# Ensure base directories exist
METRICS_DIR = BASE_DIR / "metrics"
LOGS_DIR = BASE_DIR / "logs"
METRICS_DIR.mkdir(parents=True, exist_ok=True)
LOGS_DIR.mkdir(parents=True, exist_ok=True)

@dataclass
class QueryMetrics:
    """Tracks metrics for graph queries."""
    query_hash: str
    node_id: str
    graph_size: int
    subgraph_size: int
    execution_time: float
    timestamp: datetime = field(default_factory=datetime.now)
    source_type: str = "unknown"
    cache_hit: bool = False

class MetricsTracker:
    """Tracks API usage metrics and query patterns."""
    
    def __init__(self, save_interval: int = 300):  # 5 minutes default
        self.metrics_dir = METRICS_DIR
        self.query_metrics: List[QueryMetrics] = []
        self.popular_subgraphs: Counter = Counter()
        self.endpoint_usage: Counter = Counter()
        self.error_counts: Counter = Counter()
        self.save_interval = save_interval
        self._stop_event = threading.Event()
        
        # Start background saving thread
        self._save_thread = threading.Thread(target=self._periodic_save, daemon=True)
        self._save_thread.start()
        
        # Register cleanup on exit
        atexit.register(self._cleanup)
    
    def _periodic_save(self) -> None:
        """Periodically save metrics to disk."""
        while not self._stop_event.is_set():
            time.sleep(self.save_interval)
            try:
                self.save_metrics()
                print(f"Metrics saved to {self.metrics_dir}")
            except Exception as e:
                print(f"Error saving metrics: {e}")
    
    def _cleanup(self) -> None:
        """Clean up resources and save final metrics."""
        self._stop_event.set()
        if self._save_thread.is_alive():
            self._save_thread.join()
        self.save_metrics()
        
    def track_query(self, metrics: QueryMetrics) -> None:
        """Track a graph query."""
        self.query_metrics.append(metrics)
        self.popular_subgraphs[f"{metrics.node_id}:{metrics.graph_size}"] += 1
        
    def track_endpoint(self, endpoint: str, response_time: float) -> None:
        """Track API endpoint usage."""
        self.endpoint_usage[endpoint] += 1
        
    def track_error(self, error_type: str, endpoint: str) -> None:
        """Track API errors."""
        self.error_counts[f"{endpoint}:{error_type}"] += 1
        
    def get_cache_candidates(self, min_frequency: int = 10) -> Set[str]:
        """Get frequently accessed subgraphs that are candidates for caching."""
        return {
            subgraph for subgraph, count in self.popular_subgraphs.items()
            if count >= min_frequency
        }
        
    def get_usage_report(self) -> Dict[str, Any]:
        """Generate usage report."""
        return {
            "total_queries": len(self.query_metrics),
            "endpoint_usage": dict(self.endpoint_usage),
            "error_counts": dict(self.error_counts),
            "popular_subgraphs": dict(self.popular_subgraphs)
        }
        
    def save_metrics(self) -> None:
        """Save metrics to disk."""
        print(f"Debug: Starting metrics save. Current directory: {Path.cwd()}")
        print(f"Debug: Metrics directory absolute path: {self.metrics_dir.absolute()}")
        print(f"Debug: Number of metrics to save: {len(self.query_metrics)}")
        
        if not self.query_metrics:
            print("Debug: No metrics to save, returning early")
            return
            
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        # Ensure directory exists
        try:
            self.metrics_dir.mkdir(parents=True, exist_ok=True)
            print(f"Debug: Created or verified metrics directory: {self.metrics_dir}")
        except Exception as e:
            print(f"Debug: Error creating metrics directory: {e}")
            raise
        
        try:
            # Save query metrics
            metrics_file = self.metrics_dir / f"query_metrics_{timestamp}.csv"
            df = pd.DataFrame([vars(m) for m in self.query_metrics])
            df.to_csv(metrics_file, index=False)
            print(f"Debug: Successfully wrote CSV to {metrics_file}")
            
            # Save usage report
            report_file = self.metrics_dir / f"usage_report_{timestamp}.json"
            report = self.get_usage_report()
            with open(report_file, "w") as f:
                json.dump(report, f, indent=2)
            print(f"Debug: Successfully wrote JSON to {report_file}")
                
            print(f"Saved metrics to {metrics_file} and {report_file}")
        except Exception as e:
            print(f"Debug: Error during file writing: {e}")
            raise
            
    def clear(self) -> None:
        """Clear all metrics."""
        self.query_metrics.clear()
        self.popular_subgraphs.clear()
        self.endpoint_usage.clear()
        self.error_counts.clear()

# Global metrics tracker instance
metrics = MetricsTracker() 