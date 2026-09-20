$ftpServer = "ftp.tenkasidreams.com"
$ftpPort = 21
$ftpUser = "u764430762.tenkasiupload"
$ftpPass = "MyNewlife@2026"

$tcp = New-Object System.Net.Sockets.TcpClient($ftpServer, $ftpPort)
$stream = $tcp.GetStream()
$reader = New-Object System.IO.StreamReader($stream)
$writer = New-Object System.IO.StreamWriter($stream)
$writer.AutoFlush = $true

function Read-Response {
    Start-Sleep -Milliseconds 400
    while ($stream.DataAvailable) {
        $line = $reader.ReadLine()
        if ($line -match '227 Entering Passive Mode \((.+)\)') {
            return $matches[1]
        }
    }
    return $null
}

function Send-Cmd($cmd) {
    $writer.WriteLine($cmd)
    return (Read-Response)
}

Read-Response | Out-Null
Send-Cmd "USER $ftpUser"
Send-Cmd "PASS $ftpPass"
Send-Cmd "CWD /public_html/api"

$pasv = Send-Cmd "PASV"
$parts = $pasv.Split(',')
$dataIp = "$($parts[0]).$($parts[1]).$($parts[2]).$($parts[3])"
$dataPort = ([int]$parts[4] * 256) + [int]$parts[5]
$dataTcp = New-Object System.Net.Sockets.TcpClient($dataIp, $dataPort)

Send-Cmd "RETR payments.php"

$dataStream = $dataTcp.GetStream()
$dataReader = New-Object System.IO.StreamReader($dataStream)
$content = $dataReader.ReadToEnd()
$dataReader.Close()
$dataTcp.Close()
Read-Response

Send-Cmd "QUIT"
$tcp.Close()

Write-Host "Downloaded /public_html/api/payments.php Length:" $content.Length
Write-Host "Contains 'create_order':" ($content.Contains("create_order"))
$lines = $content -split "`n"
Write-Host "Total lines:" $lines.Length
for ($i = 0; $i -lt $lines.Length; $i++) {
    if ($lines[$i] -match "Invalid action") {
        Write-Host "Line $($i+1): $($lines[$i])"
    }
}
