# PowerShell script to set up conda environment

# Check if conda is available
if (-not (Get-Command conda -ErrorAction SilentlyContinue)) {
    Write-Error "Conda is not installed or not in PATH. Please install Miniconda or Anaconda first."
    exit 1
}

# Function to handle errors
function Handle-Error {
    param($ErrorMessage)
    Write-Error $ErrorMessage
    exit 1
}

# Remove existing environment if it exists
Write-Host "Checking for existing environment..."
conda env remove -n graph-computation --quiet 2>$null

# Create and activate the environment
Write-Host "Creating conda environment 'graph-computation'..."
conda env create -f environment.yml
if ($LASTEXITCODE -ne 0) {
    Handle-Error "Failed to create conda environment. Please check environment.yml for errors."
}

# Initialize conda for PowerShell
Write-Host "Initializing conda for PowerShell..."
conda init powershell
if ($LASTEXITCODE -ne 0) {
    Handle-Error "Failed to initialize conda for PowerShell."
}

# Activate the environment (need to use conda's activate script directly in PowerShell)
Write-Host "Activating environment..."
& "$((Get-Command conda).Source)" "activate" "graph-computation"
if ($LASTEXITCODE -ne 0) {
    Handle-Error "Failed to activate conda environment."
}

# Create necessary directories
Write-Host "Creating project directories..."
$directories = @("sample_data", "output", "tests", "examples", "tools")
foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# Verify environment is working
Write-Host "Verifying Python installation..."
python -c "import pandas, networkx, numpy" 2>$null
if ($LASTEXITCODE -ne 0) {
    Handle-Error "Failed to import required packages. Environment setup may be incomplete."
}

# Run tests if they exist
if (Test-Path "tests") {
    Write-Host "Running tests..."
    python -m pytest tests/
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Some tests failed. Please check the test output above."
    }
}

Write-Host "`nSetup complete! To activate the environment in new sessions, run:"
Write-Host "conda activate graph-computation"
Write-Host "`nTo generate sample data, run:"
Write-Host "python tools/generate_data.py --help" 