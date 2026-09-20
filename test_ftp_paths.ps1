$ftpServer = "ftp.tenkasidreams.com"
$ftpPort = 21
$ftpUser = "u764430762.tenkasiupload"
$ftpPass = "MyNewlife@2026"

$tcp = New-Object System.Net.Sockets.TcpClient($ftpServer, $ftpPort)
$stream = $tcp.GetStream()
$reader = New-Object System.IO.StreamReader($stream)
$writer = New-Object System.IO.StreamWriter($stream)
$writer.AutoFlush = $true

function Send-Cmd($cmd) {
    Write-Host "> $cmd"
    $writer.WriteLine($cmd)
    Start-Sleep -Milliseconds 400
    while ($stream.DataAvailable) {
        $line = $reader.ReadLine()
        Write-Host "< $line"
    }
}

Start-Sleep -Milliseconds 500
while ($stream.DataAvailable) {
    Write-Host "< $($reader.ReadLine())"
}

Send-Cmd "USER $ftpUser"
Send-Cmd "PASS $ftpPass"
Send-Cmd "PWD"

# Check "/" contents
Send-Cmd "CWD /"
Send-Cmd "PWD"
Send-Cmd "PASV"

Send-Cmd "QUIT"
$tcp.Close()
