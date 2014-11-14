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

    try
    {
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
		$LocationID,

		[System.String]
		$LCIDHex,

		[System.String]
		$InputLocaleID
	)

	#Write-Verbose "Use this cmdlet to deliver information about command processing."

	#Write-Debug "Use this cmdlet to write debug information while troubleshooting."

	#Include this line if the resource requires a system reboot.
	#$global:DSCMachineStatus = 1

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
		$LocationID,

		[System.String]
		$LCIDHex,

		[System.String]
		$InputLocaleID
	)

    $LCIDHex = "0409"
    $InputLocaleID = "00000409"

    try
    {
        
        
        # Discover current settings for the system account
        $CurrentLocationID = Get-WinHomeLocation

        $CurrentUserLanguageList = @((Get-WinUserLanguageList).InputMethodTips.Split(':'))
		$CurrentLCIDHex = $CurrentUserLanguageList[0]
		$CurrentInputLocaleID = $CurrentUserLanguageList[1]
        


        ($LCIDHex,$InputLocaleID -join ":")



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

        Write-Host "Current Keyboard LCIDHex is $CurrentLCIDHex and InputLocaleID is $CurrentInputLocaleID"
        if (($CurrentLCIDHex,$CurrentInputLocaleID -join ":") -like ($LCIDHex,$InputLocaleID -join ":"))
        {
            Write-Host "GeoId setting is consistent"
            $GeoIdResult = $true
        }
        else
        {
            Write-Host "GeoId setting is inconsistent"
            $GeoIdResult = $false
        }

        

        Write-Verbose "Current Keyboard LCIDHex is $CurrentLCIDHex and InputLocaleID is $CurrentInputLocaleID"
        
        
        
        
        
        
        
    }
    catch
    {
        
    }
    finally
    {
        
    }


	$result = [System.Boolean]
	
	$result
}


Export-ModuleMember -Function *-TargetResource

