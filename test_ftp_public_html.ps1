$ftpUser = "u764430762.tenkasiupload"
$ftpPass = "MyNewlife@2026"
$credentials = New-Object System.Net.NetworkCredential($ftpUser, $ftpPass)

Write-Host "--- Testing ftp://ftp.tenkasidreams.com/public_html/ ---"
try {
    $req = [System.Net.FtpWebRequest]::Create("ftp://ftp.tenkasidreams.com/public_html/")
    $req.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectoryDetails
    $req.Credentials = $credentials
    $req.UsePassive = $true
    $res = $req.GetResponse()
    $reader = New-Object System.IO.StreamReader($res.GetResponseStream())
    Write-Host $reader.ReadToEnd()
    $reader.Close()
    $res.Close()
} catch {
    Write-Host "Error: " $_.Exception.Message
}
