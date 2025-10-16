#install-module microsoft.graph
. ./ipinfotoken.ps1
Connect-MgGraph -Scopes "AuditLog.Read.All"
$startDate = (Get-Date).AddDays(-4).ToString("yyyy-MM-ddTHH:mm:ssZ")
$signIns = Get-MgAuditLogSignIn -Filter "createdDateTime ge $startDate" -All

$successful = $signIns | Where-Object { $_.status.errorCode -eq 0 }

$uniqueIPs = $successful.ipAddress | Sort-Object -Unique

$ipCache = @{}

foreach ($ip in $uniqueIPs) {
    if (-not $ipCache.ContainsKey($ip)) {
        $url = "https://ipinfo.io/" + "$ip" + "?token=" + $ipInfoToken
            $response = Invoke-RestMethod -Uri $url -Method Get
            $ipCache[$ip] = $response
            Start-Sleep -Milliseconds 250  # avoid rate limits
    }
}

$enriched = $successful | ForEach-Object {
    $geo = $ipCache[$_.ipAddress]
    [PSCustomObject]@{
        User   = $_.userPrincipalName
        Date   = $_.createdDateTime
        IP     = $_.ipAddress
        City   = $geo.city
        State  = $geo.region
        Country= $geo.country
        Org    = $geo.org
    }
}

$nonIndiana = $enriched | Where-Object { $_.State -ne "Indiana" }

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

$orgname = get-mgorganization | select DisplayName

$filename = "~/Documents/" + $orgname.DisplayName + "_SuccessfulNonIndianaLogins_" + $timestamp + ".csv"

$nonIndiana | Export-Csv $filename -NoTypeInformation

Disconnect-MgGraph
