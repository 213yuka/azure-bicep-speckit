using '../main.bicep'

param location = 'japaneast'
param environmentName = 'dev'
param projectName = 'handson'
param adminUsername = 'azureadmin'
param vmssInstanceCount = 2
param vmSize = 'Standard_B2s'
param adminSshPublicKey = 'REPLACE_VIA_CI_OR_CLI'
