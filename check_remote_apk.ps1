$ftpHost = "ftp://ftp.tenkasidreams.com/TenkasiDreamsLand.apk"
$ftpUser = "u764430762.tenkasiupload"
$ftpPass = "MyNewlife@2026"
$credentials = New-Object System.Net.NetworkCredential($ftpUser, $ftpPass)

$req = [System.Net.FtpWebRequest]::Create($ftpHost)
$req.Method = [System.Net.WebRequestMethods+Ftp]::GetFileSize
$req.Credentials = $credentials
$req.UsePassive = $true
$res = $req.GetResponse()
$size = $res.ContentLength
$mb = [Math]::Round($size / 1MB, 2)
Write-Host "Remote APK File Size: $size bytes ($mb MB)"
$res.Close()
