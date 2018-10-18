$name = "NugetServer"
$location = "westeurope"

$app = New-AzureRmADApplication -DisplayName $name -IdentifierUris "https://$name.com" 

$password =  [string](Get-Random -Minimum 1000000) + [string](Get-Random -Minimum 1000000)
$securePassword = ConvertTo-SecureString -Force -AsPlainText -String $password


$sp = New-AzureRmADServicePrincipal -ApplicationId $app.ApplicationId -Password $securePassword

Start-Sleep 20


New-AzureRmRoleAssignment -RoleDefinitionName Owner -ServicePrincipalName $sp.ApplicationId -ResourceGroupName $name