Write-Host "--- 1. Testing Policy Routes ---"
$p = Invoke-WebRequest -Uri "https://tenkasidreams.com/index.php?page=privacy" -UseBasicParsing
Write-Host "Privacy Page Status: $($p.StatusCode) Length: $($p.Content.Length)"

$t = Invoke-WebRequest -Uri "https://tenkasidreams.com/index.php?page=terms" -UseBasicParsing
Write-Host "Terms Page Status: $($t.StatusCode) Length: $($t.Content.Length)"

$r = Invoke-WebRequest -Uri "https://tenkasidreams.com/index.php?page=refund" -UseBasicParsing
Write-Host "Refund Page Status: $($r.StatusCode) Length: $($r.Content.Length)"

Write-Host "`n--- 2. Testing Payment Gateway (create-order.php) ---"
$body1 = @{ amount = 100; currency = "INR"; receipt = "test_rcpt_001" } | ConvertTo-Json
$res1 = Invoke-RestMethod -Uri "https://tenkasidreams.com/api/create-order.php" -Method Post -Body $body1 -ContentType "application/json"
Write-Host "create-order.php Response:" ($res1 | ConvertTo-Json -Compress)

Write-Host "`n--- 3. Testing Payment Gateway (payments.php create_order) ---"
$body2 = @{ action = "create_order"; amount = 200; currency = "INR"; receipt = "test_rcpt_002"; property_id = "test_prop_1" } | ConvertTo-Json
$res2 = Invoke-RestMethod -Uri "https://tenkasidreams.com/api/payments.php" -Method Post -Body $body2 -ContentType "application/json"
Write-Host "payments.php create_order Response:" ($res2 | ConvertTo-Json -Compress)

Write-Host "`n--- 4. Testing Signature Verification (payments.php verify_payment with invalid signature) ---"
try {
    $body3 = @{ action = "verify_payment"; razorpay_order_id = "order_fake123"; razorpay_payment_id = "pay_fake123"; razorpay_signature = "invalid_sig" } | ConvertTo-Json
    $res3 = Invoke-RestMethod -Uri "https://tenkasidreams.com/api/payments.php" -Method Post -Body $body3 -ContentType "application/json"
    Write-Host "verify_payment Response:" ($res3 | ConvertTo-Json -Compress)
} catch {
    Write-Host "verify_payment correctly rejected invalid signature: $($_.Exception.Message)"
}
