$ErrorActionPreference = 'Stop'
$base = 'http://localhost:8080/api'

function Login($phone, $pwd) {
  $body = @{ phoneNumber = $phone; password = $pwd } | ConvertTo-Json
  try {
    $r = Invoke-RestMethod -Uri "$base/auth/login" -Method Post -Body $body -ContentType "application/json"
    return $r.data.token
  } catch {
    Write-Error "Login failed for $phone: $_"
    exit 1
  }
}

Write-Output "== START automated chat flow test =="

# 1) Login as customer
$customerToken = Login '0901234567' '123456'
Write-Output "CUSTOMER_TOKEN=$customerToken"

# 2) Create order (storeId=1, item productUnitMappingId=1)
$payload = @{
  storeId = 1
  deliveryAddress = 'Test address from automated script'
  items = @(
    @{
      productUnitMappingId = 1
      quantity = 1
    }
  )
}

try {
  $order = Invoke-RestMethod -Uri "$base/orders" -Method Post -Body ($payload | ConvertTo-Json -Depth 10) -Headers @{ Authorization = "Bearer $customerToken" } -ContentType "application/json"
  Write-Output "ORDER_ID=$($order.data.id)"
} catch {
  Write-Error "Create order failed: $_"
  exit 1
}

# 3) Create or get conversation with shipperId=3
try {
  $conv = Invoke-RestMethod -Uri "$base/chat/conversations?orderId=$($order.data.id)&shipperId=3" -Method Post -Headers @{ Authorization = "Bearer $customerToken" }
  Write-Output "CONV_ID=$($conv.data.id)"
} catch {
  Write-Error "Create conversation failed: $_"
  exit 1
}

# 4) Login as shipper and send a message
$shipperToken = Login '0903456789' '123456'
Write-Output "SHIPPER_TOKEN=$shipperToken"

$msgPayload = @{ conversationId = $conv.data.id; senderType = 'SHIPPER'; content = 'Hello from shipper (automated test)' }
try {
  $msg = Invoke-RestMethod -Uri "$base/chat/messages" -Method Post -Body ($msgPayload | ConvertTo-Json -Depth 10) -Headers @{ Authorization = "Bearer $shipperToken" } -ContentType "application/json"
  Write-Output "MSG_SENT_ID=$($msg.data.id)"
  Write-Output ($msg | ConvertTo-Json -Depth 10)
} catch {
  Write-Error "Send message failed: $_"
  exit 1
}

Write-Output "== END automated chat flow test =="
