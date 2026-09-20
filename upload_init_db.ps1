$ftpHost = "ftp://ftp.tenkasidreams.com/api/init_db.php"
$ftpUser = "u764430762.tenkasiupload"
$ftpPass = "MyNewlife@2026"
$credentials = New-Object System.Net.NetworkCredential($ftpUser, $ftpPass)

$ftpRequest = [System.Net.FtpWebRequest]::Create($ftpHost)
$ftpRequest.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
$ftpRequest.Credentials = $credentials
$ftpRequest.UseBinary = $true
$ftpRequest.UsePassive = $true

$content = [System.IO.File]::ReadAllBytes("c:\xampp\htdocs\land\api\init_db.php")
$ftpRequest.ContentLength = $content.Length
$stream = $ftpRequest.GetRequestStream()
$stream.Write($content, 0, $content.Length)
$stream.Close()
$response = $ftpRequest.GetResponse()
$response.Close()
Write-Host "Uploaded init_db.php"

Start-Sleep -Seconds 1
$res = Invoke-RestMethod -Uri "https://tenkasidreams.com/api/init_db.php?check_payments=1"
$res | ConvertTo-Json
