
# ==============================================================================================
# 
# Windows PowerShell Source File -- Created with SAPIEN Technologies PrimalScript 2015
# 
# NAME: Kiosk_Staging
# 
# AUTHOR: Mike Updike , AHIS
# DATE  : 9/15/2016
# 
# COMMENT: Allow post-imaging selection for Kiosk configuration customization
# 
# ==============================================================================================

[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName('presentationframework')

$script:scriptPath = Split-Path $MyInvocation.Mycommand.Path
$script:scriptName = $MyInvocation.MyCommand.Name.TrimEnd(".ps1")

#Function to create log file if missing.
Function Create-Log {
	#Checks for the existance of the main Logfile, and creates if missing.
	#Example: Create-Log "C:\temp\install.log"
	[CmdletBinding()]
	    param (
		[string]$FilePath
	    )
		$LogPath = Split-Path $FilePath -Parent
		$LogFile = Split-Path $FilePath -Leaf
	    try
		    {
		        if (!(Test-Path $LogPath)) {
			    	## Create the log directory
			    	New-Item $LogPath -ItemType Directory | Out-Null
				}
				If (!(Test-Path $LogFile)) {
					##Create the log file
					New-Item $LogFile -ItemType File | Out-Null
				}
				
			## Set the global variable to be used as the FilePath for all subsequent Write-Log
			## calls in this session
			$script:LogPath = $FilePath
		    }
	    catch
		    {
		        Write-Error $_.Exception.Message
		    }
	Write-Host "Script log file path is [$LogPath]"
	Write-Host "Script log file name is [$LogFile]"
}

Function Write-Log {
	#Write entries to the log file formatted for CMTrace to recognize Info, Warning, and Error levels.
	#LogLevel 1 (Defaul setting) is Informational
	#LogLevel 2 is Warning, highlighted in Yellow.
	#LogLevel 3 is Error highlighted in Red
	#Eaxmples:::::::::::::
	#Write-Log -Message 'simple activity' --- Uses default LogLevel 1 (Informational)
	#Write-Log -Message 'warning' -LogLevel 2
	#Write-Log -Message 'Error' -LogLevel 3
	param (
	    [Parameter(Mandatory = $true)]
	    [string]$Message,
	    [Parameter()]
	    [ValidateSet(1, 2, 3)]
	    [int]$LogLevel
	)
	If ($LogLevel -eq "") {$LogLevel = 1}
	$TimeGenerated = "$(Get-Date -Format HH:mm:ss).$((Get-Date).Millisecond)+000"
	$Line = '<![LOG[{0}]LOG]!><time="{1}" date="{2}" component="{3}" context="" type="{4}" thread="{4}" file="">'
	$LineFormat = $Message, $TimeGenerated, (Get-Date -Format MM-dd-yyyy), "$($MyInvocation.ScriptName | Split-Path -Leaf):$($MyInvocation.ScriptLineNumber)", $LogLevel
	$Line = $Line -f $LineFormat
	Add-Content -Value $Line -Path $script:LogPath
}

#Set standard script variables and data for logging
Create-Log "C:\logs\$scriptName.log"
$script:ScriptVersion = "1.0.0"
$script:ScriptDate = "9/15/2016"
$script:computerName = $env:computername
$script:UserName = $env:UserName

#Log all generic local details
Write-Log "Username = $script:UserName" -LogLevel 1
Write-Log "System name = $script:computername" -LogLevel 1
Write-Log "Script path = $script:scriptPath" -LogLevel 1
Write-Log "Script Version = $script:ScriptVersion" -LogLevel 1
Write-Log "Created Date = $script:ScriptDate" -LogLevel 1

#Function KioskStaging {

$inputXML = @"
<Window x:Class="Kiosk_Staging.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:Kiosk_Staging"
        mc:Ignorable="d"
        Title="Kiosk Staging" Height="446" Width="329">
    <Grid HorizontalAlignment="Left" Width="324">
        <ListBox x:Name="KioskSelection" HorizontalAlignment="Left" Height="270" VerticalAlignment="Top" Width="215" Margin="55,85,0,0">
            <RadioButton x:Name="Radio1" Content="1"/>
            <RadioButton x:Name="Radio2" Content="2"/>
            <RadioButton x:Name="Radio3" Content="3"/>
            <RadioButton x:Name="Radio4" Content="4"/>
            <RadioButton x:Name="Radio5" Content="5"/>
            <RadioButton x:Name="Radio6" Content="6"/>
            <RadioButton x:Name="Radio7" Content="7"/>
            <RadioButton x:Name="Radio8" Content="8"/>
            <RadioButton x:Name="Radio9" Content="9"/>
            <RadioButton x:Name="Radio10" Content="10"/>
            <RadioButton x:Name="Radio11" Content="11"/>
            <RadioButton x:Name="Radio12" Content="12"/>
            <RadioButton x:Name="Radio13" Content="13"/>
            <RadioButton x:Name="Radio14" Content="14"/>
            <RadioButton x:Name="Radio15" Content="15"/>
            <RadioButton x:Name="Radio16" Content="16"/>
        </ListBox>
        <TextBlock x:Name="SelectionBlock" HorizontalAlignment="Left" TextWrapping="Wrap" Text="Please select the desired kiosk configuration:" VerticalAlignment="Top" Margin="90,30,0,0" Height="40" Width="180"/>
        <Button x:Name="OK" Content="OK" HorizontalAlignment="Left" VerticalAlignment="Top" Width="75" Margin="55,380,0,0"/>
        <Image x:Name="image" HorizontalAlignment="Left" Height="65" VerticalAlignment="Top" Width="55" Source=".\company-emblem.png" Margin="30,15,0,0"/>
		<Button x:Name="Cancel" Content="Cancel" HorizontalAlignment="Left" VerticalAlignment="Top" Width="75" Margin="195,380,0,0" IsCancel="True"/>
    </Grid>
</Window>
"@
	 
	$inputXML = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace "x:C", "C" -replace '^<Win.*', '<Window'
	[xml]$XAML = $inputXML
	#Read XAML
	 
	$reader=(New-Object System.Xml.XmlNodeReader $xaml) 
	try {
		$Form=[Windows.Markup.XamlReader]::Load($reader)
	} catch {
		return $Error[0]
		#Write-Host "Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .net is installed."
		#$Exception = $_.Exception.Message
		#Write-Host $Exception
		#Write-Log "$Exception"
		exit
	}
	 
	#===========================================================================
	# Load XAML Objects In PowerShell
	#===========================================================================
	 
	$xaml.SelectNodes("//*[@Name]") | %{Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name)}
 
	Function Get-FormVariables{
		if ($global:ReadmeDisplay -ne $true){Write-host "If you need to reference this display again, run Get-FormVariables" -ForegroundColor Yellow;$global:ReadmeDisplay=$true}
		write-host "Found the following interactable elements from our form" -ForegroundColor Cyan
		get-variable WPF*
	}
 
#	Get-FormVariables{
#	}
#}

 
#===========================================================================
# Shows the form
#===========================================================================
#write-host "To show the form, run the following" -ForegroundColor Cyan
$Form.ShowDialog() | Out-Null
