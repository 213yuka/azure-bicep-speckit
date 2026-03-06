using '../main.bicep'

param location = 'japaneast'
param environmentName = 'prod'
param projectName = 'handson'
param adminUsername = 'azureadmin'
param vmssInstanceCount = 3
param vmSize = 'Standard_B2ms'
param adminSshPublicKey = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC7... placeholder-replace-with-your-public-key'
