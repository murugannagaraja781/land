Write-Host "=== 1. Testing create-order.php ===" -ForegroundColor Cyan
$orderPayload = @{
    amount = 1000 # 1000 paise = Rs 10.00
    currency = "INR"
    receipt = "rcpt_test_" + (Get-Date -UFormat %s)
} | ConvertTo-Json

try {
    $res1 = Invoke-RestMethod -Uri "http://localhost/land/api/create-order.php" -Method Post -Body $orderPayload -ContentType "application/json"
    Write-Host "SUCCESS: create-order.php" -ForegroundColor Green
    $res1 | ConvertTo-Json
    $orderId = $res1.order_id
} catch {
    Write-Host "FAILED: create-order.php - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== 2. Testing payments.php (action: create_order) ===" -ForegroundColor Cyan
$payOrderPayload = @{
    action = "create_order"
    amount = 3000 # 3000 paise = Rs 30.00
    currency = "INR"
    receipt = "rcpt_pay_" + (Get-Date -UFormat %s)
    property_id = "prop_123"
} | ConvertTo-Json

try {
    $res2 = Invoke-RestMethod -Uri "http://localhost/land/api/payments.php" -Method Post -Body $payOrderPayload -ContentType "application/json"
    Write-Host "SUCCESS: payments.php create_order" -ForegroundColor Green
    $res2 | ConvertTo-Json
    $orderId2 = $res2.order_id
} catch {
    Write-Host "FAILED: payments.php create_order - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== 3. Testing verify-payment.php with generated signature ===" -ForegroundColor Cyan
if ($orderId) {
    $mockPaymentId = "pay_mock_" + (Get-Date -UFormat %s)
    $keySecret = "bxk4gdsx48aBSjVSJd61IjLe"
    
    # Calculate HMAC-SHA256
    $hmac = New-Object System.Security.Cryptography.HMACSHA256
    $hmac.Key = [System.Text.Encoding]::UTF8.GetBytes($keySecret)
    $dataToSign = "$orderId|$mockPaymentId"
    $signatureBytes = $hmac.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($dataToSign))
    $validSignature = [System.BitConverter]::ToString($signatureBytes).Replace("-", "").ToLower()

    Write-Host "Order ID: $orderId"
    Write-Host "Mock Payment ID: $mockPaymentId"
    Write-Host "Generated Signature: $validSignature"

    $verifyPayload = @{
        razorpay_order_id = $orderId
        razorpay_payment_id = $mockPaymentId
        razorpay_signature = $validSignature
        amount = 10
        propId = "test_prop_01"
        propTitle = "Tenkasi Prime Land"
        buyerName = "Test Buyer"
        buyerPhone = "9876543210"
    } | ConvertTo-Json

    try {
        $res3 = Invoke-RestMethod -Uri "http://localhost/land/api/verify-payment.php" -Method Post -Body $verifyPayload -ContentType "application/json"
        Write-Host "SUCCESS: verify-payment.php verified correctly!" -ForegroundColor Green
        $res3 | ConvertTo-Json
    } catch {
        Write-Host "FAILED: verify-payment.php - $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-Host "`n=== 4. Testing verify with TAMPERED signature (Security check) ===" -ForegroundColor Cyan
    $tamperedPayload = @{
        razorpay_order_id = $orderId
        razorpay_payment_id = $mockPaymentId
        razorpay_signature = "bad_tampered_signature_12345"
    } | ConvertTo-Json

    try {
        $res4 = Invoke-RestMethod -Uri "http://localhost/land/api/verify-payment.php" -Method Post -Body $tamperedPayload -ContentType "application/json"
        Write-Host "SECURITY VULNERABILITY: Tampered signature was accepted!" -ForegroundColor Red
    } catch {
        Write-Host "SUCCESS: Tampered signature correctly rejected with 400 Bad Request!" -ForegroundColor Green
    }
}
