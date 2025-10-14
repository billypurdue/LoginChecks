. ﻿./getjwt.ps1
. ./ipinfotoken.ps1

$startTime = (Get-Date).ToUniversalTime().AddDays(-7).ToString("yyyy-MM-dd'T'HH:mm:ss.fff'Z'")

$baseUri = "https://admin.googleapis.com/admin/reports/v1/activity/users/all/applications/login"

$uri = "$baseUri`?startTime=$startTime&eventName=login_success"

$headers = @{
    "Authorization" = "Bearer $jwt"
    "Accept"        = "application/json"
    }


$response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers

    $loginData = foreach ($item in $response.items) {
        $ipAddress = ($item.events.parameters | Where-Object { $_.name -eq 'ip_address' }).value
        [PSCustomObject]@{
            User      = $item.actor.email
            Timestamp = Get-Date $item.id.time
            IPAddress = $item.ipAddress
        }
    }

    $loginData | Format-Table -AutoSize

$uniqueIPs = $loginData.IPAddress | Sort-Object -Unique

$ipCache = @{}

foreach ($ip in $uniqueIPs) {
    if (-not $ipCache.ContainsKey($ip)) {
        $url = "https://ipinfo.io/" + "$ip" + "?token=" + $ipInfoToken
            $response = Invoke-RestMethod -Uri $url -Method Get
            $ipCache[$ip] = $response
            Start-Sleep -Milliseconds 250  # avoid rate limits
    }
}

$enriched = $loginData | ForEach-Object {
    $geo = $ipCache[$_.IPAddress]
    [PSCustomObject]@{
        User   = $_.User
        Date   = $_.Timestamp
        IP     = $_.IPAddress
        City   = $geo.city
        State  = $geo.region
        Country= $geo.country
        Org    = $geo.org
    }
}

$nonIndiana = $enriched | Where-Object { $_.State -ne "Indiana" }

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

$orgname = "GoogleWorkspace"

$filename = $orgname + "_SuccessfulNonIndianaLogins_" + $timestamp + ".csv"

$nonIndiana | Export-Csv $filename -NoTypeInformation
