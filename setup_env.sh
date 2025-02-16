#!/bin/bash

# Check if conda is available
if ! command -v conda &> /dev/null; then
    echo "Conda is not installed or not in PATH. Please install Miniconda or Anaconda first."
    exit 1
fi

# Create and activate the environment
echo "Creating conda environment 'graph-computation'..."
conda env create -f environment.yml

# Activate the environment
echo "Activating environment..."
eval "$(conda shell.bash hook)"
conda activate graph-computation

# Create necessary directories
echo "Creating project directories..."
mkdir -p sample_data output tests examples

# Run tests to verify setup
echo "Running tests..."
python -m pytest tests/

echo -e "\nSetup complete! To activate the environment in new sessions, run:"
echo "conda activate graph-computation"

# Add environment activation to .bashrc if not already present
if ! grep -q "conda activate graph-computation" ~/.bashrc; then
    echo -e "\n# Activate graph-computation environment" >> ~/.bashrc
    echo "conda activate graph-computation" >> ~/.bashrc
    echo "Added environment activation to .bashrc"
fi 