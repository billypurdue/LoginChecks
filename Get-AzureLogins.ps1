param(
    [int]$Days = 4,
    [bool]$Automated = $false,
    [string]$CSVLocation = "~/Documents/",
    [string]$secrets = "secrets.ps1",
    [string]$status = "successful"
)

#install-module microsoft.graph
. ./ipinfotoken.ps1

if ($Automated){
    if (-not (Test-Path ./$secrets)){
            $errormessage ="Secrets file is missing!  You cannot run this automated without "+ $secrets+ " containing tenantid clientid and clientsecret!"
            write-error $errormessage
            exit 1
            }
    . ./$secrets
    $SecureClientSecret = ConvertTo-SecureString -string $clientsecret -AsPlainText

    $clientsecretcredential = new-object -typename System.Management.Automation.PSCredential -ArgumentList $clientid, $SecureClientSecret
    Connect-MgGraph -TenantId $tenantid -ClientSecretCredential $clientsecretcredential
}

else {Connect-MgGraph -Scopes "AuditLog.Read.All, Organization.Read.All"}
$startDate = (Get-Date).AddDays(-$Days).ToString("yyyy-MM-ddTHH:mm:ssZ")
$signIns = Get-MgAuditLogSignIn -Filter "createdDateTime ge $startDate" -All

write-host "Getting $status logins." -ForegroundColor Yellow
if ($status -eq "failed"){$successful = $signIns | Where-Object { (!$_.status.errorCode -eq 0) }} #get all that aren't successful
elseif ($status -eq "all"){$successful = $signIns} #get everything
else {$successful = $signIns | Where-Object { $_.status.errorCode -eq 0 }} #only get successful, the default

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
        Error  = $_.status.errorCode
	    Reason = $_.status.failureReason
	    Details = $_.status.additionalDetails
        City   = $geo.city
        State  = $geo.region
        Country= $geo.country
        Org    = $geo.org
    }
}

$nonIndiana = $enriched | Where-Object { $_.State -ne "Indiana" }

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

$orgname = get-mgorganization | select DisplayName

$filename = $CSVLocation + $orgname.DisplayName + "_" + $status + "NonIndianaLogins_" + $timestamp + ".csv"

$nonIndiana | Export-Csv $filename -NoTypeInformation

Disconnect-MgGraph
