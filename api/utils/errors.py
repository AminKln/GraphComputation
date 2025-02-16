"""Custom error definitions."""

class GraphComputationError(Exception):
    """Base exception for graph computation errors."""
    pass

class DataValidationError(GraphComputationError):
    """Raised when data validation fails."""
    pass

class DatabaseError(GraphComputationError):
    """Raised when database operations fail."""
    pass

class GraphProcessingError(GraphComputationError):
    """Raised when graph processing fails."""
    pass

class FormatError(GraphComputationError):
    """Raised when response formatting fails."""
    pass 