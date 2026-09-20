$cred = New-Object System.Net.NetworkCredential('u764430762.tenkasiupload', 'MyNewlife@2026')
$wc = New-Object System.Net.WebClient
$wc.Credentials = $cred
$wc.UploadFile('ftp://ftp.tenkasidreams.com/privacy.php', 'c:\xampp\htdocs\land\privacy.php')
Write-Host "Uploaded privacy.php successfully"
