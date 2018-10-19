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

 

I created the PSADPasswordCredential and populated it with start and end dates, a generated GUID, and my key value:

$psadCredential = New-Object Microsoft.Azure.Commands.Resources.Models.ActiveDirectory.PSADPasswordCredential

$startDate = Get-Date

$psadCredential.StartDate = $startDate

$psadCredential.EndDate = $startDate.AddYears(1)

$psadCredential.KeyId = [guid]::NewGuid()

$psadCredential.Password = $KeyValue

 

I created the application, including the PSADPasswordCredential object as the PasswordCredential parameter:

New-AzureRmADApplication –DisplayName “MyNewApp2”`

                         -HomePage $ApplicationURI `

                         -IdentifierUris $ApplicationURI `

                         -PasswordCredentials $psadCredential