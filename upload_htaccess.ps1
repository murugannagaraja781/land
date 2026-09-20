$ftpHost = "ftp://ftp.tenkasidreams.com"
$ftpUser = "u764430762.tenkasiupload"
$ftpPass = "MyNewlife@2026"
$credentials = New-Object System.Net.NetworkCredential($ftpUser, $ftpPass)

function Upload-File($local, $remote) {
    $req = [System.Net.FtpWebRequest]::Create("$ftpHost$remote")
    $req.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
    $req.Credentials = $credentials
    $req.UseBinary = $true
    $req.UsePassive = $true
    $bytes = [System.IO.File]::ReadAllBytes($local)
    $req.ContentLength = $bytes.Length
    $s = $req.GetRequestStream()
    $s.Write($bytes, 0, $bytes.Length)
    $s.Close()
    $res = $req.GetResponse()
    Write-Host "Uploaded $remote : $($res.StatusDescription)"
    $res.Close()
}

Upload-File "c:\xampp\htdocs\land\.htaccess" "/.htaccess"
Upload-File "c:\xampp\htdocs\land\api\.htaccess" "/api/.htaccess"
