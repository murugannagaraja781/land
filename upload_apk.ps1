$ftpHost = "ftp://ftp.tenkasidreams.com"
$ftpUser = "u764430762.tenkasiupload"
$ftpPass = "MyNewlife@2026"
$localApk = "c:\xampp\htdocs\land\TenkasiDreamsLand.apk"

$credentials = New-Object System.Net.NetworkCredential($ftpUser, $ftpPass)

function Upload-LargeFile($remotePath) {
    Write-Host "Uploading to $remotePath ..." -ForegroundColor Cyan
    $remoteUri = "$ftpHost$remotePath"
    $req = [System.Net.FtpWebRequest]::Create($remoteUri)
    $req.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
    $req.Credentials = $credentials
    $req.UseBinary = $true
    $req.UsePassive = $true
    $req.Timeout = 600000 # 10 minutes timeout
    $req.ReadWriteTimeout = 600000

    $fileStream = [System.IO.File]::OpenRead($localApk)
    $req.ContentLength = $fileStream.Length
    $requestStream = $req.GetRequestStream()

    $buffer = New-Object byte[] 65536 # 64KB buffer
    $totalRead = 0
    $totalLength = $fileStream.Length

    while (($read = $fileStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
        $requestStream.Write($buffer, 0, $read)
        $totalRead += $read
        $pct = [Math]::Round(($totalRead / $totalLength) * 100, 1)
        Write-Progress -Activity "Uploading APK to $remotePath" -Status "$pct% complete ($([Math]::Round($totalRead / 1MB, 1)) / $([Math]::Round($totalLength / 1MB, 1)) MB)" -PercentComplete $pct
    }

    $requestStream.Close()
    $fileStream.Close()

    $res = $req.GetResponse()
    Write-Host "SUCCESS: Uploaded to $remotePath ($($res.StatusDescription))" -ForegroundColor Green
    $res.Close()
}

Upload-LargeFile "/TenkasiDreamsLand.apk"

Write-Host "ALL APK UPLOADS COMPLETE!" -ForegroundColor Green
