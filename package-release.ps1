#Requires -Version 5.1

<#
.SYNOPSIS
    Package Foundry VTT Module for Release

.DESCRIPTION
    This script packages your Foundry VTT module for distribution by:
    1. Reading module.json to get module information
    2. Validating the manifest and download URLs
    3. Creating a ZIP archive with all necessary files
    4. Copying files to the release directory

.NOTES
    Author: Christine Benedict
    Version: 1.0.0
#>

[CmdletBinding()]
param()

# --- Configuration ---
$ErrorActionPreference = "Stop"
$releaseDir = "release"

# Read module.json to get the module name
$moduleName = "your-module-id"  # This will be read from module.json

function Write-Info { param($Message) Write-Host $Message -ForegroundColor Cyan }
function Write-Success { param($Message) Write-Host $Message -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host $Message -ForegroundColor Yellow }
function Write-Failure { param($Message) Write-Host $Message -ForegroundColor Red }

try {
    Write-Info "Reading module.json..."
    $moduleJsonPath = Join-Path $PSScriptRoot "module.json"
    if (-not (Test-Path $moduleJsonPath)) {
        throw "module.json not found at: $moduleJsonPath"
    }
    
    $moduleJson = Get-Content $moduleJsonPath -Raw | ConvertFrom-Json
    $moduleName = $moduleJson.id
    $moduleTitle = $moduleJson.title
    $moduleVersion = $moduleJson.version
    
    Write-Info "Module: $moduleTitle"
    Write-Info "ID: $moduleName"
    Write-Info "Version: $moduleVersion"
    Write-Host ""
    
    # Validate URLs
    Write-Info "Validating URLs..."
    $expectedManifest = "https://github.com/yourusername/$moduleName/releases/latest/download/module.json"
    $expectedDownload = "https://github.com/yourusername/$moduleName/releases/latest/download/$moduleName.zip"
    
    if ($moduleJson.manifest -ne $expectedManifest) {
        Write-Warning "Manifest URL should be: $expectedManifest"
        Write-Warning "Current: $($moduleJson.manifest)"
    }
    if ($moduleJson.download -ne $expectedDownload) {
        Write-Warning "Download URL should be: $expectedDownload"
        Write-Warning "Current: $($moduleJson.download)"
    }
    Write-Host ""
    
    # Prepare release directory
    Write-Info "Preparing files for packaging..."
    $releasePath = Join-Path $PSScriptRoot $releaseDir
    if (Test-Path $releasePath) {
        Remove-Item $releasePath -Recurse -Force
    }
    New-Item -ItemType Directory -Path $releasePath | Out-Null
    
    # Create ZIP archive
    $zipPath = Join-Path $releasePath "$moduleName.zip"
    Write-Info "Creating ZIP archive: $moduleName.zip"
    
    # Files and folders to include
    $includeItems = @(
        "module.json",
        "README.md",
        "LICENSE",
        "scripts",
        "styles"
    )
    
    # Create temporary directory for staging
    $tempDir = Join-Path $env:TEMP "foundry-module-package-$(Get-Date -Format 'yyyyMMddHHmmss')"
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    
    try {
        # Copy files to temp directory
        foreach ($item in $includeItems) {
            $sourcePath = Join-Path $PSScriptRoot $item
            if (Test-Path $sourcePath) {
                Copy-Item -Path $sourcePath -Destination $tempDir -Recurse -Force
            }
        }
        
        # Create ZIP from temp directory
        Compress-Archive -Path "$tempDir\*" -DestinationPath $zipPath -Force
        
        # Copy module.json to release directory
        Copy-Item -Path $moduleJsonPath -Destination (Join-Path $releasePath "module.json") -Force
        
    } finally {
        # Clean up temp directory
        if (Test-Path $tempDir) {
            Remove-Item $tempDir -Recurse -Force
        }
    }
    
    Write-Host ""
    Write-Success "Package created successfully!"
    Write-Host ""
    Write-Info "Release files created in: .\$releaseDir"
    Write-Info "  - module.json"
    Write-Info "  - $moduleName.zip"
    Write-Host ""
    
    # Display package size
    $zipSize = (Get-Item $zipPath).Length / 1KB
    Write-Info ("Package size: {0:N2} KB" -f $zipSize)
    Write-Host ""
    
    # Next steps
    Write-Info "--- Next Steps ---"
    Write-Info "1. Commit and push your changes to GitHub"
    Write-Info "2. Create a new release at: https://github.com/yourusername/$moduleName/releases/new"
    Write-Info "3. Tag the release as: v$moduleVersion"
    Write-Info "4. Upload both files from the 'release' directory:"
    Write-Info "   - module.json"
    Write-Info "   - $moduleName.zip"
    Write-Info "5. Publish the release"
    Write-Host ""
    Write-Info "Manifest URL for Foundry: $expectedManifest"
    
} catch {
    Write-Failure "Error: $_"
    Write-Host $_.ScriptStackTrace
    exit 1
}
