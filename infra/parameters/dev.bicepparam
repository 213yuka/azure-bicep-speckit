using '../main.bicep'

param location = 'japaneast'
param environmentName = 'dev'
param projectName = 'handson'
param adminUsername = 'azureadmin'
param vmssInstanceCount = 2
param vmSize = 'Standard_B2s'
param adminSshPublicKey = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC7... placeholder-replace-with-your-public-key'
