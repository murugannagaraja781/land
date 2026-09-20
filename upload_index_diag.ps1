$ftpHost = "ftp://ftp.tenkasidreams.com/index.php"
$ftpUser = "u764430762.tenkasiupload"
$ftpPass = "MyNewlife@2026"
$credentials = New-Object System.Net.NetworkCredential($ftpUser, $ftpPass)

$ftpRequest = [System.Net.FtpWebRequest]::Create($ftpHost)
$ftpRequest.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
$ftpRequest.Credentials = $credentials
$ftpRequest.UseBinary = $true
$ftpRequest.UsePassive = $true

$content = [System.IO.File]::ReadAllBytes("c:\xampp\htdocs\land\index.php")
$ftpRequest.ContentLength = $content.Length
$stream = $ftpRequest.GetRequestStream()
$stream.Write($content, 0, $content.Length)
$stream.Close()
$response = $ftpRequest.GetResponse()
$response.Close()
Write-Host "Uploaded index.php"

Start-Sleep -Seconds 1
try {
    $res = Invoke-RestMethod -Uri "https://tenkasidreams.com/index.php?page=debug_diag"
    $res | ConvertTo-Json
} catch {
    Write-Host "Error fetching debug_diag:" $_.Exception.Message
}
