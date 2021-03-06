function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Name = "UserLocale"
	)

    ClearDown

    try
    {
        $Culture = (Get-Culture).name
        $LocationID = Get-WinHomeLocation
        Write-Verbose "Current WinHomeLocation is $($LocationID.HomeLocation), GeoId is $($LocationID.GeoId)"

        $UserLanguageList = @((Get-WinUserLanguageList).InputMethodTips.Split(':'))
		$LCIDHex = $UserLanguageList[0]
		$InputLocaleID = $UserLanguageList[1]
        Write-Verbose "Current Keyboard LCIDHex is $LCIDHex and InputLocaleID is $InputLocaleID"
    }
    catch
    {
        
    }
    finally
    {
        
    }

	$returnValue = @{
		Name = $Name
		Culture = $Culture
        LocationID = $LocationID.GeoId
		LCIDHex = $LCIDHex
		InputLocaleID = $InputLocaleID
	}

	$returnValue
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Name = "UserLocale",

		[System.String]
		$Culture,

		[System.String]
		$LocationID,

		[System.String]
		$LCIDHex,

		[System.String]
		$InputLocaleID
	)

    try
    {
        ClearDown

        # Set current user's settings before copying the affected registry hives to the rest of the local users
        Set-WinHomeLocation $LocationID
        Set-Culture $Culture
        Set-WinUserLanguageList $Culture -Force
        Set-WinUILanguageOverride $Culture
        
        ClearDown

        $null = New-PSDrive -Name HKU   -PSProvider Registry -Root Registry::HKEY_USERS
        reg load HKU\DEFAULT_USER C:\Users\Default\NTUSER.DAT
        Set-Location HKU:\

        $currentSID = (New-Object System.Security.Principal.NTAccount((whoami))).Translate([System.Security.Principal.SecurityIdentifier]).value
        Write-Verbose "Current Users SID is $currentSID"

        # Remove backup regional settings to prevent conflicts
        if (Test-Path -Path "HKU:\$currentSID\Control Panel\International\User Profile System Backup")
        {
            Write-Verbose "Delete current User Backup Profile"
            Remove-Item "HKU:\$currentSID\Control Panel\International\User Profile System Backup" -Recurse -Force
        }

        Write-Verbose "Making changes to all local users..."

        # Copy current user's locale settings to all local user's registry hives, but skip system and default hives
        Get-ChildItem | Where-Object { ! ($_.Name -match ".*Classes$")} | ForEach-Object {
            
            $path = (Resolve-Path $_).path

            # Skip current user's and default registry hive as we loop through all existing users
            # Note: DEFAULT is a copy of SYSTEM
            if (($currentSID -like $_.PSChildName) -or (".DEFAULT" -like $_.PSChildName))
            {
                Write-Verbose "`nSkipping System and DEFAULT user regstry hives...`n"

            }
            else
            {

                Write-Verbose "`nForce all local user culture settigns to $Culture"

                if (Test-Path -Path "$path\Control Panel\International")
                {
                    Write-Verbose "`nRemoving $path\Control Panel\International"
                    Remove-Item "$path\Control Panel\International" -Recurse -Force

                    Write-Verbose "Copying current user International settings to $path\Control Panel\International"
                    Copy-Item "HKCU:\Control Panel\International" -Destination "$path\Control Panel" -Recurse -Force
                }

                Write-Verbose "Force default keyboard language to $Culture for $currentSID"
                
                if (Test-Path -Path "$path\Keyboard Layout\Preload")
                {
                    Remove-ItemProperty "$path\Keyboard Layout\Preload" -Name "1" -Force
                }
                Set-ItemProperty "$path\Keyboard Layout\Preload" -Name "1" -Value $InputLocaleID -Type String -Force
            }
        }

        Set-Location C:\
        Remove-PSDrive HKU
        ClearDown
        reg unload HKU\DEFAULT_USER
        
        Write-Verbose "User Reginal Settings DONE"

    }
    catch
    {
        $error[0].Exception
    }

	# Resource requires a system reboot after changing system user's settings
	$global:DSCMachineStatus = 1

}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Name = "UserLocale",

		[System.String]
		$Culture,

		[System.String]
		$LocationID,

		[System.String]
		$LCIDHex,

		[System.String]
		$InputLocaleID
	)

    try
    {
        # Discover current settings for the system account
        $CurrentCulture = (Get-Culture).name
        $CurrentLocationID = Get-WinHomeLocation
        $CurrentUserLanguageList = (Get-WinUserLanguageList).InputMethodTips
        $CurrentLCIDHex = $CurrentUserLanguageList.Split(':')[0]
        $CurrentInputLocaleID = $CurrentUserLanguageList.Split(':')[1]

        Write-Verbose "Current CurrentCulture is $CurrentCulture"
        if ($CurrentCulture -like $Culture)
        {
            Write-Verbose "Culture setting is consistent - $CurrentCulture"
            $CultureResult = $true
        }
        else
        {
            Write-Verbose "Culture setting is inconsistent - $CurrentCulture"
            $CultureResult = $false
        }

        Write-Verbose "Current WinHomeLocation is $($CurrentLocationID.HomeLocation), GeoId is $($CurrentLocationID.GeoId)"
        if ($($CurrentLocationID.GeoId) -like $LocationID)
        {
            Write-Verbose "GeoId setting is consistent"
            $GeoIdResult = $true
        }
        else
        {
            Write-Verbose "GeoId setting is inconsistent"
            $GeoIdResult = $false
        }

        Write-Verbose "Current Keyboard LCIDHex is $CurrentLCIDHex and InputLocaleID is $CurrentInputLocaleID"
        if ($CurrentUserLanguageList -like ($LCIDHex,$InputLocaleID -join ":"))
        {
            Write-Verbose "Input setting is consistent"
            $InputResult = $true
        }
        else
        {
            Write-Verbose "Input setting is inconsistent"
            $InputResult = $false
        }

        if (($InputResult -eq $true) -and ($GeoIdResult -eq $true) -and ($CultureResult -eq $true))
        {
            $result = $true
            Write-Verbose "All settings are consistent"
        }
        else
        {
            $result = $false
            Write-Verbose "Some or all settings are inconsistent"
        }

    }
    catch
    {
        
    }
    finally
    {
        
    }
	
	$result
}


# Garbage collection function
function ClearDown {
[gc]::Collect()
[gc]::WaitForPendingFinalizers()
}


Export-ModuleMember -Function *-TargetResource
