// ============================================================================
// Key Vaultモジュール（プライベートエンドポイント付き）
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

@description('プライベートエンドポイントを配置するサブネットID')
param subnetId string

@description('仮想ネットワークID（プライベートDNSゾーンリンク用）')
param vnetId string

// ============================================================================
// 変数定義 - CAF命名規則
// ============================================================================

var keyVaultName = 'kv-${projectName}-${environmentName}-${take(uniqueString(resourceGroup().id), 6)}'

// ============================================================================
// Key Vault - RBAC認証 / ソフトデリート90日 / パージ保護有効
// ============================================================================

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
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

// ============================================================================
// プライベートDNSゾーン - Vault
// ============================================================================

resource privateDnsZoneVault 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.vaultcore.azure.net'
  location: 'global'
  tags: tags
}

// ============================================================================
// プライベートDNSゾーン - VNetリンク
// ============================================================================

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZoneVault
  name: 'link-vault-${projectName}-${environmentName}'
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

// ============================================================================
// プライベートエンドポイント - Vault
// ============================================================================

resource keyVaultPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-01-01' = {
  name: 'pe-kv-${projectName}-${environmentName}'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'psc-kv-${projectName}-${environmentName}'
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

// ============================================================================
// プライベートDNSゾーングループ
// ============================================================================

resource dnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-01-01' = {
  parent: keyVaultPrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config-vault'
        properties: {
          privateDnsZoneId: privateDnsZoneVault.id
        }
      }
    ]
  }
}

// ============================================================================
// 出力定義
// ============================================================================

output keyVaultName string = keyVault.name
output keyVaultId string = keyVault.id
output keyVaultUri string = keyVault.properties.vaultUri
