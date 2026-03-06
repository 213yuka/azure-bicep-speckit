// ============================================================================
// VMSSモジュール - Webサーバー (Linux Ubuntu 22.04 LTS)
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

@description('VMSSを配置するサブネットID')
param subnetId string

@description('管理者ユーザー名')
param adminUsername string

@description('管理者SSH公開鍵')
param adminSshPublicKey string

@description('VMSSインスタンス数')
param instanceCount int

@description('VMのサイズ')
param vmSize string

@description('Log AnalyticsワークスペースID')
param logAnalyticsWorkspaceId string

@description('Application Gatewayバックエンドプール ID')
param appGatewayBackendPoolId string = ''

// ============================================================================
// 変数定義 - CAF命名規則
// ============================================================================

var vmssName = 'vmss-${projectName}-${environmentName}'

// Log AnalyticsワークスペースIDの参照（AMA連携用）
#disable-next-line no-unused-vars
var logWorkspaceRef = logAnalyticsWorkspaceId

// ============================================================================
// VMSS リソース定義
// ============================================================================

resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2024-03-01' = {
  name: vmssName
  location: location
  tags: tags
  zones: [
    '1'
    '2'
    '3'
  ]
  sku: {
    name: vmSize
    tier: 'Standard'
    capacity: instanceCount
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    overprovision: false
    upgradePolicy: {
      mode: 'Manual'
    }
    singlePlacementGroup: false
    platformFaultDomainCount: 1
    virtualMachineProfile: {
      // ============================================================================
      // OS プロファイル - SSH公開鍵認証
      // ============================================================================
      osProfile: {
        computerNamePrefix: 'web'
        adminUsername: adminUsername
        linuxConfiguration: {
          disablePasswordAuthentication: true
          ssh: {
            publicKeys: [
              {
                path: '/home/${adminUsername}/.ssh/authorized_keys'
                keyData: adminSshPublicKey
              }
            ]
          }
        }
      }
      // ============================================================================
      // ストレージプロファイル - Ubuntu 22.04 LTS
      // ============================================================================
      storageProfile: {
        imageReference: {
          publisher: 'Canonical'
          offer: '0001-com-ubuntu-server-jammy'
          sku: '22_04-lts-gen2'
          version: 'latest'
        }
        osDisk: {
          createOption: 'FromImage'
          caching: 'ReadWrite'
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
        }
      }
      // ============================================================================
      // ネットワークプロファイル - AppGWバックエンドプール連携
      // ============================================================================
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: 'nic-${vmssName}'
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: 'ipconfig1'
                  properties: {
                    primary: true
                    subnet: {
                      id: subnetId
                    }
                    applicationGatewayBackendAddressPools: empty(appGatewayBackendPoolId)
                      ? []
                      : [
                          {
                            id: appGatewayBackendPoolId
                          }
                        ]
                  }
                }
              ]
            }
          }
        ]
      }
      // ============================================================================
      // 拡張機能プロファイル - nginx インストール・AMA
      // ============================================================================
      extensionProfile: {
        extensions: [
          {
            name: 'install-nginx'
            properties: {
              publisher: 'Microsoft.Azure.Extensions'
              type: 'CustomScript'
              typeHandlerVersion: '2.1'
              autoUpgradeMinorVersion: true
              settings: {
                commandToExecute: 'apt-get update && apt-get install -y nginx && systemctl enable nginx && systemctl start nginx'
              }
            }
          }
          {
            name: 'AzureMonitorLinuxAgent'
            properties: {
              publisher: 'Microsoft.Azure.Monitor'
              type: 'AzureMonitorLinuxAgent'
              typeHandlerVersion: '1.33'
              autoUpgradeMinorVersion: true
              enableAutomaticUpgrade: true
            }
          }
        ]
      }
      // ============================================================================
      // 診断プロファイル
      // ============================================================================
      diagnosticsProfile: {
        bootDiagnostics: {
          enabled: true
        }
      }
    }
  }
}

// ============================================================================
// 出力定義
// ============================================================================

output vmssName string = vmss.name
output vmssId string = vmss.id
