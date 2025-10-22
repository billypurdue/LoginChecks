# Login-Checks

A collection of simple PowerShell scripts to audit successful logins from Azure and Google Workspace, enrich the data with geolocation info, and filter for activity outside a specific region.  The Azure script defaults to a manual workflow, with options to support automation; the Google script is already more setup for automation because of the way a security token is required for authentication (unlike Azure where we can get prompted to authenticate to the Graph API in the web browser).

These scripts were built for function, not perfection. They get the job done for a specific use case but can be adapted as needed. 🛠️

---

## What It Does

This project contains two main scripts:

1.  `Get-AzureLogins.ps1`: Pulls successful Azure AD sign-in logs for a specified number of days.
2.  `Get-GoogleLogins.ps1`: Pulls successful Google Workspace login events for a specified number of days.

Both scripts perform the following workflow:
* **Fetch Logins:** They query the respective platform's API for successful login events over the last 'X' days.
* **Enrich IP Data:** For each login event, the public IP address is sent to the `ipinfo.io` API to gather geolocation data (like city, region, country, etc.).
* **Filter:** The script then filters these logins to show only those originating from **outside Indiana**. This is easily changed in the script to suit your own needs.
* **Export:** The final, enriched, and filtered data is exported to a `.csv` file in the same directory where the script is run.

---

##  Prerequisites

Before running the scripts, you **must create two files** in the same directory. These files are ignored by `.gitignore` to protect your sensitive credentials.

### 1. `ipinfotoken.ps1`

This file must contain your API key from [ipinfo.io](https://ipinfo.io/). The script assumes you are using a **free tier API key**. A paid key will return a slightly different JSON object and will break the script.

Create a file named `ipinfotoken.ps1` and add the following line, replacing `YOUR_API_KEY_HERE` with your actual token:

```powershell
$ipInfoToken = "YOUR_API_KEY_HERE"
```

### 2. `getjwt.ps1` (For Google Lookups Only)

To query the Google Reports API, you need a valid Java Web Token (JWT). How you generate this is up to you, but the end result must be a variable named `$jwt` containing the token.

The JWT must have the following scope: `https://www.googleapis.com/auth/admin.reports.audit.readonly`

Create a file named `getjwt.ps1`. Your script to generate the token goes here. For example:

```powershell
# Your code to generate the JWT goes here.
# The final token string must be stored in the $jwt variable.

$jwt = "ey....YOUR_JWT_HERE..._9w"
```
### 3. `secrets.ps1` (optional, for Azure Only)

For fully automated execution of the script you'll need to provide a secrets file containing $clientid, $clientsecret, and $tenantid.
```powershell
$clientid = "your-client-id"
$clientsecret = "your-client-secret"
$tenantid = "your-tenant-id"
```
The default file for this is secrets.ps1, however you can specify an alternative by passing the -secrets flag to the script.
```powershell
Get-AzureLogins.ps1 -Automate:$true -secrets mysecret.ps1
```
More secure options for secret storage are coming.

---

## Manual Usage (Azure)
By default, the script will return the last four days of successful logins, and will prompt you to login to authenticate against the Microsoft Graph API.  You'll need to have AuditLog.Read.All and Organization.Read.All permissions.  To specify a different number of days you can use the -Days flag with the script
```powershell
Get-AzureLogins.ps1 -Days 2
```
The script will process the data and create a CSV file.

## Automation

In addition to configuring the secrets file as specified above, you'll also need to create the Enterprise Application in Azure for automating the login audit for Azure logs.  There are plenty of guides on the Internet for setting these up, the important bits are that it will require AuditLog.Read.All and Organization.Read.All.

The script will process the data and create a CSV file.

## Flags

### -Days (optional)
Specify the number of days to get logs for - the default is 4
```powershell
Get-AzureLogins.ps1 -Days 23
```

### -Automated (optional, Azure Only)
By default this is set to false, set it to true if you want to use a client secret file for automation.
```powershell
Get-AzureLogins.ps1 -Automated:$true
```

### -CSVLocation (optional)
Specifies where to save the output file - the default is ~/Documents/" which should deliver the file to the Documents folder in Windows, Linux, and MacOS.
```powershell
Get-AzureLogins.ps1 -CSVLocation "c:\users\hodor\csv files\"
```

### -secrets (optional, Azure Only)
Specifies an alternative secrets file, which is secrets.ps1 by default; this is handy if you're automating for more than one Azure tenant.  This would require setting Automated to true as well.
```powershell
Get-AzureLogins.ps1 -Automated:$true -secrets HodorsHealth.ps1
```

### - status (optional)
What login types do you want to see - default is successful.  Options are failed, all, or successful.
```powershell
Get-AzureLogins.ps1 -status all
```

