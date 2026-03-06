// =============================================================================
// Azure IaC Handson - メインデプロイメントファイル
// =============================================================================

targetScope = 'subscription'

// -----------------------------------------------------------------------------
// パラメータ
// -----------------------------------------------------------------------------

@description('デプロイ先のリージョン')
param location string = 'japaneast'

@description('環境名 (dev, staging, prod)')
@allowed([
  'dev'
  'staging'
  'prod'
])
param environmentName string = 'dev'

@description('プロジェクト名')
param projectName string = 'handson'

// -----------------------------------------------------------------------------
// 変数
// -----------------------------------------------------------------------------

var resourceGroupName = 'rg-${projectName}-${environmentName}-${location}'
var tags = {
  project: projectName
  environment: environmentName
  managedBy: 'bicep'
  createdDate: '2026-03-06'
}

// -----------------------------------------------------------------------------
// リソースグループ
// -----------------------------------------------------------------------------

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// -----------------------------------------------------------------------------
// モジュールデプロイ
// -----------------------------------------------------------------------------

module network 'modules/network.bicep' = {
  scope: rg
  name: 'network-deployment'
  params: {
    location: location
    environmentName: environmentName
    projectName: projectName
    tags: tags
  }
}

module storage 'modules/storage.bicep' = {
  scope: rg
  name: 'storage-deployment'
  params: {
    location: location
    environmentName: environmentName
    projectName: projectName
    tags: tags
    subnetId: network.outputs.defaultSubnetId
  }
}

module keyVault 'modules/keyvault.bicep' = {
  scope: rg
  name: 'keyvault-deployment'
  params: {
    location: location
    environmentName: environmentName
    projectName: projectName
    tags: tags
    subnetId: network.outputs.defaultSubnetId
  }
}

// -----------------------------------------------------------------------------
// 出力
// -----------------------------------------------------------------------------

output resourceGroupName string = rg.name
output vnetName string = network.outputs.vnetName
output storageAccountName string = storage.outputs.storageAccountName
output keyVaultName string = keyVault.outputs.keyVaultName
