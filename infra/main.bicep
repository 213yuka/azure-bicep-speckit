// ============================================================================
// メインテンプレート - CAF/WAF準拠 冗長Webサーバーアーキテクチャ
// ============================================================================
targetScope = 'subscription'

// ============================================================================
// パラメーター定義
// ============================================================================

@description('デプロイ先のリージョン')
param location string = 'japaneast'

@description('環境名')
@allowed([
  'dev'
  'staging'
  'prod'
])
param environmentName string = 'dev'

@description('プロジェクト名')
param projectName string = 'handson'

@description('VMSS管理者ユーザー名')
param adminUsername string

@description('VMSS管理者SSH公開鍵')
param adminSshPublicKey string

@description('VMSSインスタンス数')
@minValue(2)
@maxValue(5)
param vmssInstanceCount int = 2

@description('VMのサイズ')
param vmSize string = 'Standard_B2s'

// ============================================================================
// 変数定義
// ============================================================================

var tags = {
  project: projectName
  environment: environmentName
  managedBy: 'bicep'
  repository: 'azure-bicep-speckit'
  architecture: 'caf-waf-webserver'
}

var rgName = 'rg-${projectName}-${environmentName}-${location}'

// ============================================================================
// リソースグループ
// ============================================================================

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgName
  location: location
  tags: tags
}

// ============================================================================
// ネットワークモジュール
// ============================================================================

module network 'modules/network.bicep' = {
  name: 'deploy-network'
  scope: rg
  params: {
    location: location
    environmentName: environmentName
    projectName: projectName
    tags: tags
  }
}

// ============================================================================
// Log Analyticsモジュール
// ============================================================================

module logAnalytics 'modules/log-analytics.bicep' = {
  name: 'deploy-log-analytics'
  scope: rg
  params: {
    location: location
    environmentName: environmentName
    projectName: projectName
    tags: tags
  }
}

// ============================================================================
// ストレージアカウントモジュール（プライベートエンドポイント付き）
// ============================================================================

module storage 'modules/storage.bicep' = {
  name: 'deploy-storage'
  scope: rg
  params: {
    location: location
    environmentName: environmentName
    projectName: projectName
    tags: tags
    subnetId: network.outputs.privateEndpointSubnetId
    vnetId: network.outputs.vnetId
  }
}

// ============================================================================
// Key Vaultモジュール（プライベートエンドポイント付き）
// ============================================================================

module keyVault 'modules/keyvault.bicep' = {
  name: 'deploy-keyvault'
  scope: rg
  params: {
    location: location
    environmentName: environmentName
    projectName: projectName
    tags: tags
    subnetId: network.outputs.privateEndpointSubnetId
    vnetId: network.outputs.vnetId
  }
}

// ============================================================================
// Application Gateway + WAFモジュール
// ============================================================================

module appGateway 'modules/appgateway.bicep' = {
  name: 'deploy-appgateway'
  scope: rg
  params: {
    location: location
    environmentName: environmentName
    projectName: projectName
    tags: tags
    subnetId: network.outputs.appGatewaySubnetId
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
  }
}

// ============================================================================
// VMSS Webサーバーモジュール
// ============================================================================

module vmss 'modules/vmss.bicep' = {
  name: 'deploy-vmss'
  scope: rg
  params: {
    location: location
    environmentName: environmentName
    projectName: projectName
    tags: tags
    subnetId: network.outputs.webSubnetId
    adminUsername: adminUsername
    adminSshPublicKey: adminSshPublicKey
    instanceCount: vmssInstanceCount
    vmSize: vmSize
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    appGatewayBackendPoolId: appGateway.outputs.backendAddressPoolId
  }
}
