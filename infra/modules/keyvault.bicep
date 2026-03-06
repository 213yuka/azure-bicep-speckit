// =============================================================================
// Key Vault モジュール
// =============================================================================

@description('デプロイ先のリージョン')
param location string

@description('環境名')
param environmentName string

@description('プロジェクト名')
param projectName string

@description('リソースタグ')
param tags object

@description('Private Endpoint用サブネットID')
param subnetId string

// -----------------------------------------------------------------------------
// 変数
// -----------------------------------------------------------------------------

// Key Vault名は英数字とハイフンのみ、3-24文字
var keyVaultName = 'kv-${projectName}-${environmentName}-${uniqueString(resourceGroup().id)}'

// -----------------------------------------------------------------------------
// Key Vault
// -----------------------------------------------------------------------------

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: take(keyVaultName, 24)
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
}

// -----------------------------------------------------------------------------
// Private Endpoint
// -----------------------------------------------------------------------------

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-01-01' = {
  name: 'pe-${keyVault.name}-vault'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'plsc-${keyVault.name}-vault'
        properties: {
          privateLinkServiceId: keyVault.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
  }
}

// -----------------------------------------------------------------------------
// 出力
// -----------------------------------------------------------------------------

output keyVaultName string = keyVault.name
output keyVaultId string = keyVault.id
output keyVaultUri string = keyVault.properties.vaultUri
