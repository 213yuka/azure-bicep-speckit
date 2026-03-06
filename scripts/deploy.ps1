# =============================================================================
# Azure IaC Handson - デプロイスクリプト
# =============================================================================

param(
    [ValidateSet('dev', 'staging', 'prod')]
    [string]$Environment = 'dev',
    
    [string]$Location = 'japaneast',
    
    [switch]$WhatIf,
    
    [switch]$Validate
)

$ErrorActionPreference = 'Stop'

$templateFile = Join-Path $PSScriptRoot '..\infra\main.bicep'
$parameterFile = Join-Path $PSScriptRoot "..\infra\parameters\$Environment.bicepparam"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Azure IaC Handson - Deploy ($Environment)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Template:   $templateFile"
Write-Host "Parameters: $parameterFile"
Write-Host "Location:   $Location"
Write-Host ""

# パラメータファイルの存在チェック
if (-not (Test-Path $parameterFile)) {
    Write-Error "Parameter file not found: $parameterFile"
    exit 1
}

$deploymentName = "handson-$Environment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

if ($Validate) {
    Write-Host ">> Validating deployment..." -ForegroundColor Yellow
    az deployment sub validate `
        --location $Location `
        --template-file $templateFile `
        --parameters $parameterFile `
        --name $deploymentName
}
elseif ($WhatIf) {
    Write-Host ">> Running What-If analysis..." -ForegroundColor Yellow
    az deployment sub what-if `
        --location $Location `
        --template-file $templateFile `
        --parameters $parameterFile `
        --name $deploymentName
}
else {
    Write-Host ">> Deploying to Azure..." -ForegroundColor Green
    az deployment sub create `
        --location $Location `
        --template-file $templateFile `
        --parameters $parameterFile `
        --name $deploymentName
}

Write-Host ""
Write-Host "Done." -ForegroundColor Green
