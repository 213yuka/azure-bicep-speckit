// =============================================================================
// ネットワークモジュール - VNet & サブネット
// =============================================================================

@description('デプロイ先のリージョン')
param location string

@description('環境名')
param environmentName string

@description('プロジェクト名')
param projectName string

@description('リソースタグ')
param tags object

// -----------------------------------------------------------------------------
// 変数
// -----------------------------------------------------------------------------

var vnetName = 'vnet-${projectName}-${environmentName}-${location}'
var nsgName = 'nsg-${projectName}-${environmentName}-${location}'

// -----------------------------------------------------------------------------
// NSG (ネットワークセキュリティグループ)
// -----------------------------------------------------------------------------

resource nsg 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'DenyAllInbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// -----------------------------------------------------------------------------
// VNet (仮想ネットワーク)
// -----------------------------------------------------------------------------

resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'snet-default'
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: 'snet-app'
        properties: {
          addressPrefix: '10.0.2.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
          delegations: []
        }
      }
    ]
  }
}

// -----------------------------------------------------------------------------
// 出力
// -----------------------------------------------------------------------------

output vnetName string = vnet.name
output vnetId string = vnet.id
output defaultSubnetId string = vnet.properties.subnets[0].id
output appSubnetId string = vnet.properties.subnets[1].id
