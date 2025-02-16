"""Health check routes."""

from flask import Blueprint, jsonify

from api import __version__

bp = Blueprint("health", __name__, url_prefix="/api/v1")

@bp.route("/health", methods=["GET"])
def health_check():
    """Health check endpoint."""
    return jsonify({
        "status": "healthy",
        "version": __version__
    }) 