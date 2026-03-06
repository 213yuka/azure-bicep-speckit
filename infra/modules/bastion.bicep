// ============================================================================
// Azure Bastion モジュール（Basic SKU - 最小コスト構成）
// ============================================================================

// ============================================================================
// パラメーター定義
// ============================================================================

@description('デプロイ先のリージョン')
param location string

@description('環境名')
param environmentName string

@description('プロジェクト名')
param projectName string

@description('リソースタグ')
param tags object

@description('AzureBastionSubnet の ID')
param subnetId string

// ============================================================================
// 変数定義 - CAF命名規則
// ============================================================================

var bastionName = 'bas-${projectName}-${environmentName}'
var bastionPipName = 'pip-bas-${projectName}-${environmentName}'

// ============================================================================
// パブリック IP（Bastion 用、Standard SKU 必須）
// ============================================================================

resource bastionPip 'Microsoft.Network/publicIPAddresses@2024-01-01' = {
  name: bastionPipName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// ============================================================================
// Azure Bastion（Basic SKU）
// ============================================================================

resource bastion 'Microsoft.Network/bastionHosts@2024-01-01' = {
  name: bastionName
  location: location
  tags: tags
  sku: {
    name: 'Basic'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'bastionIpConfig'
        properties: {
          publicIPAddress: {
            id: bastionPip.id
          }
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
}

// ============================================================================
// 出力定義
// ============================================================================

output bastionName string = bastion.name
output bastionId string = bastion.id
