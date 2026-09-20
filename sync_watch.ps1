# ==========================================================
# Tenkasi Dreams Land - Continuous Auto-Sync Watcher Script
# Automatically uploads modified files to Hostinger Live Server
# Run this script: powershell -ExecutionPolicy Bypass -File .\sync_watch.ps1
# ==========================================================

$ftpHost = "ftp://ftp.tenkasidreams.com"
$ftpUser = "u764430762.tenkasiupload"
$ftpPass = "MyNewlife@2026"
$watchFolder = $PWD.Path
$credentials = New-Object System.Net.NetworkCredential($ftpUser, $ftpPass)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  TENKASI DREAMS LAND - CONTINUOUS AUTO-SYNC WATCHER" -ForegroundColor Cyan
Write-Host "  Monitoring: $watchFolder" -ForegroundColor Gray
Write-Host "  Destination: $ftpHost (Hostinger /public_html)" -ForegroundColor Gray
Write-Host "  Press Ctrl+C to stop watching." -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

# Function to upload a single file via FTP
function Upload-FileToFtp($fullPath) {
    if (-not (Test-Path $fullPath -PathType Leaf)) { return }

    # Calculate relative path
    $relPath = $fullPath.Substring($watchFolder.Length).TrimStart("\/")
    
    # Ignore build, git, dart, flutter files
    if ($relPath -match "^(\.git|\.dart_tool|build|android|ios|windows|linux|macos|\.idea|\.gemini|lib|test)" -or
        $relPath -match "\.apk$" -or $relPath -match "sync_watch\.ps1$") {
        return
    }

    $remotePath = "/" + ($relPath -replace "\\", "/")
    $ftpUri = "$ftpHost$remotePath"

    $time = Get-Date -Format "HH:mm:ss"
    Write-Host "[$time] 🔄 Detected change: $relPath" -ForegroundColor Yellow

    try {
        # Ensure remote directory exists
        $remoteDir = [System.IO.Path]::GetDirectoryName($remotePath) -replace "\\", "/"
        if ($remoteDir -and $remoteDir -ne "/" -and $remoteDir -ne "") {
            $dirUri = "$ftpHost$remoteDir"
            try {
                $dirReq = [System.Net.FtpWebRequest]::Create($dirUri)
                $dirReq.Credentials = $credentials
                $dirReq.Method = [System.Net.WebRequestMethods+Ftp]::MakeDirectory
                $dirReq.UsePassive = $true
                $dirResp = $dirReq.GetResponse()
                $dirResp.Close()
            } catch {
                # Directory likely already exists
            }
        }

        # Upload file
        $req = [System.Net.FtpWebRequest]::Create($ftpUri)
        $req.Credentials = $credentials
        $req.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
        $req.UseBinary = $true
        $req.UsePassive = $true

        $bytes = [System.IO.File]::ReadAllBytes($fullPath)
        $req.ContentLength = $bytes.Length

        $stream = $req.GetRequestStream()
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Close()

        $response = $req.GetResponse()
        $response.Close()

        Write-Host "[$time] ✅ Uploaded: $relPath -> $remotePath" -ForegroundColor Green
    } catch {
        Write-Host "[$time] ❌ Upload failed for $relPath : $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Create FileSystemWatcher
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $watchFolder
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true
$watcher.NotifyFilter = [System.IO.NotifyFilters]::FileName -bor [System.IO.NotifyFilters]::LastWrite

$action = {
    $path = $Event.SourceEventArgs.FullPath
    $changeType = $Event.SourceEventArgs.ChangeType
    
    # Wait 200ms to allow file writes to finish
    Start-Sleep -Milliseconds 200
    Upload-FileToFtp $path
}

Register-ObjectEvent $watcher "Changed" -Action $action | Out-Null
Register-ObjectEvent $watcher "Created" -Action $action | Out-Null

Write-Host "🟢 Watcher is actively monitoring. Any saved changes will upload automatically!" -ForegroundColor Green
Write-Host ""

# Keep PowerShell loop alive
try {
    while ($true) {
        Start-Sleep -Seconds 1
    }
} finally {
    Unregister-Event -SourceIdentifier * -ErrorAction SilentlyContinue
    $watcher.Dispose()
    Write-Host "`n🛑 Auto-sync watcher stopped." -ForegroundColor Yellow
}
