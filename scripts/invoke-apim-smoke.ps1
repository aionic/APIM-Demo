param(
  [Parameter(Mandatory = $true)]
  [string]$GatewayUrl,

  [Parameter(Mandatory = $true)]
  [string]$SubscriptionKey,

  [switch]$IncludeLlm,
  [switch]$FailOnHttpError
)

$ErrorActionPreference = "Stop"

$base = $GatewayUrl.TrimEnd("/")
$requests = @(
  @{
    Name   = "weather"
    Method = "GET"
    Url    = "$base/weather/forecast?latitude=47.6062&longitude=-122.3321"
    Body   = $null
  },
  @{
    Name   = "time"
    Method = "GET"
    Url    = "$base/time/get?source=apim-smoke"
    Body   = $null
  },
  @{
    Name   = "echo"
    Method = "GET"
    Url    = "$base/echo/get?source=apim-smoke"
    Body   = $null
  }
)

if ($IncludeLlm) {
  $requests += @{
    Name   = "llm"
    Method = "POST"
    Url    = "$base/llm/chat/completions"
    Body   = @{
      model    = "gpt-4o-mini"
      messages = @(
        @{
          role    = "user"
          content = "hello"
        }
      )
      max_tokens = 16
    } | ConvertTo-Json -Depth 5
  }
}

$results = foreach ($req in $requests) {
  $correlationId = [guid]::NewGuid().ToString()
  $headers = @{
    "Ocp-Apim-Subscription-Key" = $SubscriptionKey
    "x-correlation-id"          = $correlationId
  }

  $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
  $response = Invoke-WebRequest -Method $req.Method -Uri $req.Url -Headers $headers -Body $req.Body -ContentType "application/json" -SkipHttpErrorCheck
  $stopwatch.Stop()

  [pscustomobject]@{
    Api           = $req.Name
    StatusCode    = [int]$response.StatusCode
    DurationMs    = [int]$stopwatch.ElapsedMilliseconds
    CorrelationId = $correlationId
    Url           = $req.Url
  }
}

$results | Format-Table -AutoSize

$failed = $results | Where-Object { $_.StatusCode -lt 200 -or $_.StatusCode -ge 400 }
if ($FailOnHttpError -and $failed) {
  Write-Error "One or more API calls failed. See status table above."
}
