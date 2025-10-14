# Login-Checks

A collection of simple PowerShell scripts to audit successful logins from Azure and Google Workspace, enrich the data with geolocation info, and filter for activity outside a specific region.

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

---

## Usage

1.  Ensure you have created the two prerequisite files listed above.
2.  Open PowerShell and navigate to the project directory.
3.  Adjust the days in $startdate if you want to.

```

The script will process the data and create a CSV file.