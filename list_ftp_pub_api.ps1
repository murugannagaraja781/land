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
        Write-Host "< $line"
        if ($line -match '227 Entering Passive Mode \((.+)\)') {
            return $matches[1]
        }
    }
    return $null
}

function Send-Cmd($cmd) {
    Write-Host "> $cmd"
    $writer.WriteLine($cmd)
    return (Read-Response)
}

Read-Response | Out-Null
Send-Cmd "USER $ftpUser"
Send-Cmd "PASS $ftpPass"
Send-Cmd "CWD /public_html/api"
Send-Cmd "PWD"

$pasv = Send-Cmd "PASV"
if ($pasv) {
    $parts = $pasv.Split(',')
    $dataIp = "$($parts[0]).$($parts[1]).$($parts[2]).$($parts[3])"
    $dataPort = ([int]$parts[4] * 256) + [int]$parts[5]
    
    $dataTcp = New-Object System.Net.Sockets.TcpClient($dataIp, $dataPort)
    Send-Cmd "LIST"
    
    $dataStream = $dataTcp.GetStream()
    $dataReader = New-Object System.IO.StreamReader($dataStream)
    Write-Host "=== LIST /public_html/api ==="
    Write-Host $dataReader.ReadToEnd()
    $dataReader.Close()
    $dataTcp.Close()
    Read-Response
}

Send-Cmd "QUIT"
$tcp.Close()
