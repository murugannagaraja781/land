$ftpHost = "ftp://ftp.tenkasidreams.com/api/opcache_clear.php"
$ftpUser = "u764430762.tenkasiupload"
$ftpPass = "MyNewlife@2026"
$credentials = New-Object System.Net.NetworkCredential($ftpUser, $ftpPass)

$ftpRequest = [System.Net.FtpWebRequest]::Create($ftpHost)
$ftpRequest.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
$ftpRequest.Credentials = $credentials
$ftpRequest.UseBinary = $true
$ftpRequest.UsePassive = $true

$content = [System.IO.File]::ReadAllBytes("c:\xampp\htdocs\land\api\opcache_clear.php")
$ftpRequest.ContentLength = $content.Length
$stream = $ftpRequest.GetRequestStream()
$stream.Write($content, 0, $content.Length)
$stream.Close()

$response = $ftpRequest.GetResponse()
Write-Host "Uploaded opcache_clear.php:" $response.StatusDescription
$response.Close()
