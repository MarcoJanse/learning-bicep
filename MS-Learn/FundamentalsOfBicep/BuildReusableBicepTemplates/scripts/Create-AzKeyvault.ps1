$keyVaultName = 'mcj76-mslearn-keyvault' # A unique name for the key vault.
$login = Read-Host -Prompt "Enter the SQL administrator login name you used in the previous step"
$password = Read-Host -Prompt "Enter the SQL administrator password you used in the previous step"

$sqlServerAdministratorLogin = ConvertTo-SecureString $login -AsPlainText -Force
$sqlServerAdministratorPassword = ConvertTo-SecureString $password -AsPlainText -Force

New-AzKeyVault -VaultName $keyVaultName -Location westeurope -EnabledForTemplateDeployment
Set-AzKeyVaultSecret -VaultName $keyVaultName -Name 'sqlServerAdministratorLogin' -SecretValue $sqlServerAdministratorLogin
Set-AzKeyVaultSecret -VaultName $keyVaultName -Name 'sqlServerAdministratorPassword' -SecretValue $sqlServerAdministratorPassword