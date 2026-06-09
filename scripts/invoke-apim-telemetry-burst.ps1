param(
  [Parameter(Mandatory = $true)]
  [string]$GatewayUrl,

  [Parameter(Mandatory = $true)]
  [string]$SubscriptionKey,

  [int]$Iterations = 30,
  [int]$DelayMs = 400,
  [switch]$FailOnHttpError
)

$ErrorActionPreference = "Stop"

$base = $GatewayUrl.TrimEnd("/")
$routes = @(
  "$base/weather/forecast?latitude=47.6062&longitude=-122.3321",
  "$base/time/timezone/Etc/UTC",
  "$base/echo/get?source=apim-burst"
)

$results = New-Object System.Collections.Generic.List[object]
$startUtc = (Get-Date).ToUniversalTime()

for ($i = 1; $i -le $Iterations; $i++) {
  $route = Get-Random -InputObject $routes
  $correlationId = [guid]::NewGuid().ToString()
  $headers = @{
    "Ocp-Apim-Subscription-Key" = $SubscriptionKey
    "x-correlation-id"          = $correlationId
  }

  $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
  $response = Invoke-WebRequest -Method GET -Uri $route -Headers $headers -SkipHttpErrorCheck
  $stopwatch.Stop()

  $results.Add([pscustomobject]@{
      Iteration     = $i
      StatusCode    = [int]$response.StatusCode
      DurationMs    = [int]$stopwatch.ElapsedMilliseconds
      CorrelationId = $correlationId
      Url           = $route
    })

  Start-Sleep -Milliseconds $DelayMs
}

$results | Group-Object StatusCode | Sort-Object Name | ForEach-Object {
  [pscustomobject]@{
    StatusCode = $_.Name
    Count      = $_.Count
  }
} | Format-Table -AutoSize

$summary = [pscustomobject]@{
  Requests        = $results.Count
  MinDurationMs   = ($results | Measure-Object DurationMs -Minimum).Minimum
  AvgDurationMs   = [math]::Round(($results | Measure-Object DurationMs -Average).Average, 2)
  MaxDurationMs   = ($results | Measure-Object DurationMs -Maximum).Maximum
  FirstRequestUtc = $startUtc
  LastRequestUtc  = (Get-Date).ToUniversalTime()
}

$summary | Format-List

$failed = $results | Where-Object { $_.StatusCode -lt 200 -or $_.StatusCode -ge 400 }
if ($FailOnHttpError -and $failed) {
  Write-Error "Burst run completed with failed requests."
}
