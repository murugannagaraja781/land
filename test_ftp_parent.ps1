$ftpHost = "ftp://ftp.tenkasidreams.com/../"
$ftpUser = "u764430762.tenkasiupload"
$ftpPass = "MyNewlife@2026"
$credentials = New-Object System.Net.NetworkCredential($ftpUser, $ftpPass)

$ftpRequest = [System.Net.FtpWebRequest]::Create($ftpHost)
$ftpRequest.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectoryDetails
$ftpRequest.Credentials = $credentials
$ftpRequest.UsePassive = $true

try {
    $response = $ftpRequest.GetResponse()
    $reader = New-Object System.IO.StreamReader($response.GetResponseStream())
    Write-Host "FTP .. Contents:"
    Write-Host $reader.ReadToEnd()
    $reader.Close()
    $response.Close()
} catch {
    Write-Host "Error accessing .. :" $_.Exception.Message
}
