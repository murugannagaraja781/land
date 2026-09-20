$body = @{
    action = "create_order"
    amount = 200
    currency = "INR"
    receipt = "rcpt_live_test_" + (Get-Date -UFormat %s)
} | ConvertTo-Json

Write-Host "Sending POST with Body:" $body

try {
    $res = Invoke-RestMethod -Uri "https://tenkasidreams.com/api/payments.php?action=create_order" -Method Post -Body $body -ContentType "application/json"
    Write-Host "SUCCESS! Order Created:"
    $res | ConvertTo-Json
} catch {
    Write-Host "FAILED. Status:" $_.Exception.Response.StatusCode
    $stream = $_.Exception.Response.GetResponseStream()
    if ($stream) {
        $reader = New-Object System.IO.StreamReader($stream)
        Write-Host "Body:" $reader.ReadToEnd()
    }
}
