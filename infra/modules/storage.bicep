// =============================================================================
// ストレージアカウントモジュール
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

// ストレージアカウント名は英数字小文字のみ、3-24文字
var storageAccountName = 'st${projectName}${environmentName}${uniqueString(resourceGroup().id)}'

// -----------------------------------------------------------------------------
// ストレージアカウント
// -----------------------------------------------------------------------------

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: take(storageAccountName, 24)
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
}

// -----------------------------------------------------------------------------
// Blob サービス
// -----------------------------------------------------------------------------

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

// -----------------------------------------------------------------------------
// Private Endpoint
// -----------------------------------------------------------------------------

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-01-01' = {
  name: 'pe-${storageAccount.name}-blob'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'plsc-${storageAccount.name}-blob'
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

// -----------------------------------------------------------------------------
// 出力
// -----------------------------------------------------------------------------

output storageAccountName string = storageAccount.name
output storageAccountId string = storageAccount.id
