// ============================================================================
// ストレージアカウントモジュール（プライベートエンドポイント付き）
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

var storageAccountName = take('st${projectName}${environmentName}${uniqueString(resourceGroup().id)}', 24)

// ============================================================================
// ストレージアカウント - StorageV2 / Standard_LRS / TLS 1.2
// ============================================================================

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
}

// ============================================================================
// Blobサービス - ソフトデリート7日間
// ============================================================================

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

// ============================================================================
// プライベートDNSゾーン - Blob
// ============================================================================

resource privateDnsZoneBlob 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.blob.${environment().suffixes.storage}'
  location: 'global'
  tags: tags
}

// ============================================================================
// プライベートDNSゾーン - VNetリンク
// ============================================================================

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZoneBlob
  name: 'link-blob-${projectName}-${environmentName}'
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
// プライベートエンドポイント - Blob
// ============================================================================

resource storagePrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-01-01' = {
  name: 'pe-st-${projectName}-${environmentName}'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'psc-st-${projectName}-${environmentName}'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'blob'
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
  parent: storagePrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config-blob'
        properties: {
          privateDnsZoneId: privateDnsZoneBlob.id
        }
      }
    ]
  }
}

// ============================================================================
// 出力定義
// ============================================================================

output storageAccountName string = storageAccount.name
output storageAccountId string = storageAccount.id
