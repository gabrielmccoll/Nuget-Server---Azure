$name = "NugetServer"
$location = "westeurope"

$app = New-AzureRmADApplication -DisplayName $name -IdentifierUris "https://$name.com" 

$password =  [string](Get-Random -Minimum 1000000) + [string](Get-Random -Minimum 1000000)
$securePassword = ConvertTo-SecureString -Force -AsPlainText -String $password


$sp = New-AzureRmADServicePrincipal -ApplicationId $app.ApplicationId -Password $securePassword 

Start-Sleep 20


New-AzureRmRoleAssignment -RoleDefinitionName Owner -ServicePrincipalName $sp.ApplicationId -ResourceGroupName $name

#https://www.sabin.io/blog/adding-an-azure-active-directory-application-and-key-using-powershell/

function Create-AesManagedObject($key, $IV) {

    $aesManaged = New-Object "System.Security.Cryptography.AesManaged"
    $aesManaged.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $aesManaged.Padding = [System.Security.Cryptography.PaddingMode]::Zeros
    $aesManaged.BlockSize = 128
    $aesManaged.KeySize = 256

    if ($IV) {
        if ($IV.getType().Name -eq "String") {
            $aesManaged.IV = [System.Convert]::FromBase64String($IV)
        }
        else {
            $aesManaged.IV = $IV
        }
    }

    if ($key) {
        if ($key.getType().Name -eq "String") {
            $aesManaged.Key = [System.Convert]::FromBase64String($key)
        }
        else {
            $aesManaged.Key = $key
        }
    }

    $aesManaged
}



function Create-AesKey() {
    $aesManaged = Create-AesManagedObject 
    $aesManaged.GenerateKey()
    [System.Convert]::ToBase64String($aesManaged.Key)
}

#Create the 44-character key value

$keyValue = Create-AesKey




$appsecret = New-AzureRmADAppCredential -ApplicationId $sp.ApplicationId -Password (ConvertTo-SecureString ($keyValue) -AsPlainText -Force) -EndDate (Get-Date).AddMonths(12)

"********
copy this down , you need it later  it's the app secret key   >>    " + $keyValue

"This is the application / service principal ID . copy this too >>  " +  $app.ApplicationId 