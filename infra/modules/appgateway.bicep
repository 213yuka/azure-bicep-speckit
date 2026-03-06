// ============================================================================
// Application Gateway + WAFモジュール
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

@description('Application Gatewayを配置するサブネットID')
param subnetId string

@description('バックエンドプールFQDN（空の場合はVMSS NIC連携）')
param backendPoolFqdn string = ''

@description('Log AnalyticsワークスペースID')
param logAnalyticsWorkspaceId string

// ============================================================================
// 変数定義 - CAF命名規則
// ============================================================================

var appGatewayName = 'agw-${projectName}-${environmentName}'
var publicIpName = 'pip-agw-${projectName}-${environmentName}'
var wafPolicyName = 'wafpol-${projectName}-${environmentName}'
var backendPoolName = 'bp-${projectName}-${environmentName}'

// ============================================================================
// パブリックIP - Standard SKU / ゾーン冗長
// ============================================================================

resource publicIp 'Microsoft.Network/publicIPAddresses@2024-01-01' = {
  name: publicIpName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// ============================================================================
// WAFポリシー - OWASP 3.2 / Prevention モード
// ============================================================================

resource wafPolicy 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2024-01-01' = {
  name: wafPolicyName
  location: location
  tags: tags
  properties: {
    customRules: []
    policySettings: {
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      fileUploadLimitInMb: 100
      state: 'Enabled'
      mode: 'Prevention'
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'OWASP'
          ruleSetVersion: '3.2'
        }
      ]
    }
  }
}

// ============================================================================
// Application Gateway v2 - WAF_v2 SKU / オートスケール 2-10
// ============================================================================

resource appGateway 'Microsoft.Network/applicationGateways@2024-01-01' = {
  name: appGatewayName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
    }
    autoscaleConfiguration: {
      minCapacity: 2
      maxCapacity: 10
    }
    // ============================================================================
    // ゲートウェイIP構成
    // ============================================================================
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: subnetId
          }
        }
      }
    ]
    // ============================================================================
    // フロントエンドIP構成
    // ============================================================================
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIp'
        properties: {
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
    // ============================================================================
    // フロントエンドポート - HTTP 80
    // ============================================================================
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
    ]
    // ============================================================================
    // バックエンドアドレスプール
    // ============================================================================
    backendAddressPools: [
      {
        name: backendPoolName
        properties: {
          backendAddresses: empty(backendPoolFqdn)
            ? []
            : [
                {
                  fqdn: backendPoolFqdn
                }
              ]
        }
      }
    ]
    // ============================================================================
    // バックエンドHTTP設定
    // ============================================================================
    backendHttpSettingsCollection: [
      {
        name: 'httpSettings'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          requestTimeout: 30
          probe: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/probes',
              appGatewayName,
              'healthProbe'
            )
          }
        }
      }
    ]
    // ============================================================================
    // HTTPリスナー - ポート80
    // ============================================================================
    httpListeners: [
      {
        name: 'httpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/frontendIPConfigurations',
              appGatewayName,
              'appGatewayFrontendIp'
            )
          }
          frontendPort: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/frontendPorts',
              appGatewayName,
              'port_80'
            )
          }
          protocol: 'Http'
        }
      }
    ]
    // ============================================================================
    // ルーティングルール
    // ============================================================================
    requestRoutingRules: [
      {
        name: 'routingRule'
        properties: {
          priority: 100
          ruleType: 'Basic'
          httpListener: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/httpListeners',
              appGatewayName,
              'httpListener'
            )
          }
          backendAddressPool: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/backendAddressPools',
              appGatewayName,
              backendPoolName
            )
          }
          backendHttpSettings: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/backendHttpSettingsCollection',
              appGatewayName,
              'httpSettings'
            )
          }
        }
      }
    ]
    // ============================================================================
    // ヘルスプローブ - パス /
    // ============================================================================
    probes: [
      {
        name: 'healthProbe'
        properties: {
          protocol: 'Http'
          path: '/'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: true
        }
      }
    ]
    // ============================================================================
    // WAFポリシー参照
    // ============================================================================
    firewallPolicy: {
      id: wafPolicy.id
    }
  }
}

// ============================================================================
// 診断設定 - Log Analytics連携
// ============================================================================

resource appGatewayDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-${appGatewayName}'
  scope: appGateway
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'ApplicationGatewayAccessLog'
        enabled: true
      }
      {
        category: 'ApplicationGatewayPerformanceLog'
        enabled: true
      }
      {
        category: 'ApplicationGatewayFirewallLog'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// ============================================================================
// 出力定義
// ============================================================================

output appGatewayName string = appGateway.name
output appGatewayId string = appGateway.id
output publicIpAddress string = publicIp.properties.ipAddress
output backendAddressPoolId string = resourceId(
  'Microsoft.Network/applicationGateways/backendAddressPools',
  appGateway.name,
  backendPoolName
)
