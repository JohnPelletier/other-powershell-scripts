#
#This script creates a self-signed cert and puts it in the documents directory for the current user.
#
$NewCertCreateParameters = @{
    Subject = 'a.ayxcloud.com'
    CertStoreLocation = 'Cert:\CurrentUser\My'
    NotAfter = (Get-Date -Date 06/03/2022 -Hour 17).AddYears(1)
    KeyExportPolicy = 'Exportable'
    OutVariable = 'Certificate'
} # End.

New-SelfSignedCertificate @NewCertCreateParameters | Out-Null

Get-ChildItem -Path $NewCertCreateParameters.CertStoreLocation |
    Where-Object Thumbprint -eq $Certificate.Thumbprint |
    Select-Object -Property *

$CertPassword = ConvertTo-SecureString -String 'Sunflower!Dance#' -Force -AsPlainText
 
$NewCertExportParameters = @{
    Cert = "Cert:\CurrentUser\My\$($Certificate.Thumbprint)"
    FilePath = "$env:USERPROFILE\Documents\JPCert.pfx"
    Password = $CertPassword
} # End.
Export-PfxCertificate @NewCertExportParameters | Out-Null
 
Get-Item -Path $NewCertExportParameters.FilePath
#Remove-Item -Path $NewCertExportParameters.FilePath
#Remove-Item -Path $NewCertExportParameters.Cert