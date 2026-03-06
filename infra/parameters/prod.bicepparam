using '../main.bicep'

param location = 'japaneast'
param environmentName = 'prod'
param projectName = 'handson'
param adminUsername = 'azureadmin'
param vmssInstanceCount = 3
param vmSize = 'Standard_B2ms'
param adminSshPublicKey = 'REPLACE_VIA_CI_OR_CLI'
