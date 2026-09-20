try {
    $body = @{ action = "create_order"; amount = 200; currency = "INR"; receipt = "test_rcpt_002" } | ConvertTo-Json
    $res = Invoke-RestMethod -Uri "https://tenkasidreams.com/api/payments.php" -Method Post -Body $body -ContentType "application/json"
    Write-Host "Success:" ($res | ConvertTo-Json -Compress)
} catch {
    Write-Host "Status: $($_.Exception.Response.StatusCode)"
    $stream = $_.Exception.Response.GetResponseStream()
    if ($stream) {
        $reader = New-Object System.IO.StreamReader($stream)
        Write-Host "Response Body: $($reader.ReadToEnd())"
    }
}
