<# 
.NAME
    DiskCleaner by Jim Tyler, PowerShellEngineer.com
    Twitter: @PowerShellEng
    Github: @PowerShellEng
    YouTube: @PowerShellEng
#>

#Define default log location
$logfile = "C:\temp\diskcleaner.log"

#==========Localization Variables==========
#GUI Variables
$FormTitleText = "Disk Cleaner by Jim Tyler (PowerShellEngineer.com)"
$SelectDiskLabelText = "Select Disk:"
$FreeSpaceLabelText = "Free Space (GB): "
$TotalSpaceLabelText = "Total Space (GB): "
$JunkFoundLabelText = "Junk Found (GB):"
$CleanDiskBtnText = "Clean Disk *Warning - Deletes Files*"
$SpaceCleanedLabelText = "Space Cleaned (GB): "
$LogFileLabelText = "Log File Located: $logfile"
$CreditLabelText = "Script by Jim Tyler - PowerShellEngineer.com"

# .Net methods for hiding/showing the console in the background 
Add-Type -Name Window -Namespace Console -MemberDefinition ' [DllImport("Kernel32.dll")] public static extern IntPtr GetConsoleWindow(); [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow); ' 

#Check the C Drive - this is the default drive to be checked. Users can change it in the dropdown combobox
$c = Get-Volume -DriveLetter C

function Select-BrowserProcesses() {
    $runningCount = 0
    if(Get-Process | Where-Object {$_.ProcessName -like "*Edge*"}) { $runningCount++ }
    if(Get-Process | Where-Object {$_.ProcessName -like "*Chrome*"}) { $runningCount++ }
    if(Get-Process | Where-Object {$_.ProcessName -like "*Firefox*"}) { $runningCount++ }
    if(Get-Process | Where-Object {$_.ProcessName -like "*Opera*"}) { $runningCount++ }
    if(Get-Process | Where-Object {$_.ProcessName -like "*Iexplore*"}) { $runningCount++ }
    if($runningCount -gt 0) {
        return $true
    } else {
        return $false
    }
}

#Function to Show the PowerShell Console Behind the Windows Forms GUI
function Show-Console { 
$consolePtr = [Console.Window]::GetConsoleWindow() 
# Hide = 0, 
	# ShowNormal = 1, 
	# ShowMinimized = 2, 
	# ShowMaximized = 3, 
	# Maximize = 3, 
	# ShowNormalNoActivate = 4, 
	# Show = 5, 
	# Minimize = 6, 
	# ShowMinNoActivate = 7, 
	# ShowNoActivate = 8, 
	# Restore = 9, 
	# ShowDefault = 10, 
	# ForceMinimized = 11 

[Console.Window]::ShowWindow($consolePtr, 4) 
}



<# 
.NAME
    DiskCleaner by Jim Tyler, PowerShellEngineer.com
    Twitter: @PowerShellEng
    Github: @PowerShellEng
    YouTube: @PowerShellEng
#>



#Function to Hide the PowerShell Console Behind the Windows Forms GUI
function Hide-Console { 
	$consolePtr = [Console.Window]::GetConsoleWindow() 
	#0 hide 
	[Console.Window]::ShowWindow($consolePtr, 0) 
} 





#Function to Calculate Drive Size and Junk
function Get-DriveJunk() {
    [CmdletBinding()]
    param(
        #Drive letter of drive to be checked.
        [Parameter(Position=0,mandatory=$true)]
        [string] $DriveLetter,

        #Optional - LogFile Location, default is C:\temp\diskcleaner.log
        [Parameter(Position=1,mandatory=$false)]
        [string] $logfile,

        #Optional - Checks files to delete older than the specified day count.
        #For example, if $OlderThan = 30, all files with date modified dates older than 30 days will be deleted when running Clear-DriveJunk.
        [Parameter(Position=1,mandatory=$false)]
        [int32] $OlderThan 
    )

    #Building the drive string; the environment has an issue when you try to echo a string with the value of 
    $colon = ":"
    $DriveString = "$DriveLetter$colon"
    
    #Paths array - paths of directories and log files that build up over time and need to be cleared. 
    $pathsToClear = @("C:\WINDOWS\SoftwareDistribution\Download","$DriveString\WINDOWS\winsxs\backup","$DriveString\WINDOWS\Installer\$PatchCache$","$DriveString\WINDOWS\help","$DriveString\WINDOWS\Web\Wallpaper","$DriveString\Windows\Installer","$DriveString\Windows\Logs\WindowsUpdate","$DriveString\Windows\Logs\waasmediccapsule","$DriveString\Windows\Logs\waasmedic","$DriveString\Windows\Logs\SIH","$DriveString\Windows\Logs\NetSetup","$DriveString\Windows\Logs\MoSetup","$DriveString\Windows\Logs\MeasuredBoot","$DriveString\Windows\Logs\DPX","$DriveString\Windows\Logs\DISM","$DriveString\Windows\Logs\CBS","$DriveString\Windows\Logs\StorGroupPolicy.log","$DriveString\Windows\System32\CatRoot2\dberr.txt","$DriveString\Windows\debug","$DriveString\Windows\security\logs\scecomp.old","$DriveString\Windows\security\logs\scecomp.log","$DriveString\Windows\SysWOW64\Gms.log","$DriveString\Windows\SharedPCSetup.log","$DriveString\Windows\stuperr.log","$DriveString\Windows\setupact.log","$DriveString\Windows\PFRO.log","$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*","$env:LOCALAPPDATA\Microsoft\Terminal Server Client\Cache","$DriveString\Windows\system32\FNTCACHE.DAT","$DriveString\Windows\Temp","$env:LOCALAPPDATA\Temp","$env:LOCALAPPDATA\Microsoft\Edge\User Data","$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache")                    #Script by Jim Tyler, PowerShellEngineer.com                                                

    Foreach ($path in $pathsToClear) {

        #Check if it exists
        if(Test-Path -Path $path) {

            #Write-Host "We found stuff at $path"

            #Check to see if the path is a directory. Calculating size of a directory vs. a file is different
            $isDir = (Get-Item $path) -is [System.IO.DirectoryInfo]
            if($isDir) {
                Write-Host "Directory: $path"
                $dir = Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum | Select-Object Sum, Count
                $junkFound += $dir.Sum
            } else {
                Write-Host "File: $path"
                $file = Get-ChildItem -Path $path -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum | Select-Object Sum, Count
                $junkFound += $file.Sum
            }
            #end assessing if it's a directory
        } else {

            Write-Host "We can't seem to find $path"

        }
    }

    #Create custom hashtable with results.
    $returnHashTable = @{

        "JunkFound" = [math]::Round(($junkFound/ 1GB),2)

    }
    
    #Return that table as an object
    return new-object psobject -Property $returnHashTable

}#End Clear-DriveJunk function Declaration







function Clear-DriveJunk() {
    [CmdletBinding()]
    param(
        #Drive to be cleaned
        [Parameter(Position=0,mandatory=$true)]
        [string] $DriveLetter,

        #Optional - LogFile Location, default is C:\temp\diskcleaner.log
        [Parameter(Position=1,mandatory=$false)]
        [string] $LogFile, 

        #Deletes files older than the specified day count.
        #For example, if $OlderThan = 30, all files with date modified dates older than 30 days will be deleted.      
        [Parameter(Position=2,mandatory=$false)]
        [int32] $OlderThan,

        #Empty Recycle Bin for specified drive; empties by default
        #Set to $true/$false
        [Parameter(Position=3,mandatory=$false)]
        [bool] $EmptyRecycleBin,

        #Ignore if Browsers are open and attempt to delete files. It may cause issues with open browsers.
        #By default, this script asks to you to close all browsers and halts processing.
        #Set to $true/$false
        [Parameter(Position=4,mandatory=$false)]
        [bool] $IgnoreBrowsers,

        #Automatically close all browser processes before cleaning if set to true.
        #By default, this will be false if not set
        #Set to $true/$false
        [Parameter(Position=5,mandatory=$false)]
        [bool] $CloseBrowsers
    )

    #Write log that slimming has started...
    $timestamp = Get-Date
    $msg = "$timestamp - Clean attempt started for drive $DriveLetter ..."
    Write-Host $msg 
    $msg | Add-Content $logfile

    #Assess current disk size
    $timestamp = Get-Date
    $driveObj = Get-Volume -DriveLetter $DriveLetter
    $diskSize = [math]::Round(($driveObj.Size/ 1GB),2)
    $diskFreeSpace = [math]::Round(($driveObj.SizeRemaining/ 1GB),2)
    $msg = "$timestamp - Disk Size: $diskSize GB --- Disk Free Space: $diskFreeSpace GB"
    $msg | Add-Content $logfile

    #Building the drive string; the environment has an issue when you try to echo a string with the value of 
    $colon = ":"
    $DriveString = "$DriveLetter$colon"

    $pathsToClear = @("C:\WINDOWS\SoftwareDistribution\Download","$DriveString\WINDOWS\winsxs\backup","$DriveString\WINDOWS\Installer\$PatchCache$","$DriveString\WINDOWS\help","$DriveString\WINDOWS\Web\Wallpaper","$DriveString\Windows\Installer","$DriveString\Windows\Logs\WindowsUpdate","$DriveString\Windows\Logs\waasmediccapsule","$DriveString\Windows\Logs\waasmedic","$DriveString\Windows\Logs\SIH","$DriveString\Windows\Logs\NetSetup","$DriveString\Windows\Logs\MoSetup","$DriveString\Windows\Logs\MeasuredBoot","$DriveString\Windows\Logs\DPX","$DriveString\Windows\Logs\DISM","$DriveString\Windows\Logs\CBS","$DriveString\Windows\Logs\StorGroupPolicy.log","$DriveString\Windows\System32\CatRoot2\dberr.txt","$DriveString\Windows\debug","$DriveString\Windows\security\logs\scecomp.old","$DriveString\Windows\security\logs\scecomp.log","$DriveString\Windows\SysWOW64\Gms.log","$DriveString\Windows\SharedPCSetup.log","$DriveString\Windows\stuperr.log","$DriveString\Windows\setupact.log","$DriveString\Windows\PFRO.log","$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*","$env:LOCALAPPDATA\Microsoft\Terminal Server Client\Cache","$DriveString\Windows\system32\FNTCACHE.DAT","$DriveString\Windows\Temp","$env:LOCALAPPDATA\Temp","$env:LOCALAPPDATA\Microsoft\Edge\User Data","$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache")                    #Script by Jim Tyler, PowerShellEngineer.com                                                

    Foreach ($path in $pathsToClear) {

        #Check if it exists
        if(Test-Path -Path $path) {

            #Write-Host "We found stuff at $path"

            #Check to see if the path is a directory. Calculating size of a directory vs. a file is different
            $isDir = (Get-Item $path) -is [System.IO.DirectoryInfo]
            if($isDir) {
                $timestamp = Get-Date
                $msg = "$timestamp - Deleting contents of directory: $path"
                Write-Host $msg 
                $msg | Add-Content $logfile
                $dir = Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum | Select-Object Sum, Count
                $junkFound += $dir.Sum

                #Actually delete the contents of the folder
                Get-ChildItem -Path $path -Include *.* -File -Recurse | ForEach-Object {
                     Remove-Item -Path $_ -Force
                     if((Test-Path -path $_) -eq $true) { $junkNotRemoved += $dir.sum } else { $junkRemoved += $dir.sum } 
                }

            } else {
                $timestamp = Get-Date
                $msg = "$timestamp - Deleting file: $path"
                Write-Host $msg 
                $msg | Add-Content $logfile
                $file = Get-ChildItem -Path $path -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum | Select-Object Sum, Count
                $junkFound += $file.Sum

                #Actually delete the file 
                Remove-Item -Path $path -Force
                if((Test-Path -path $path) -eq $true) { $junkNotRemoved += $dir.sum } else { $junkRemoved += $dir.sum }
            }
            #end assessing if it's a directory
        } 
    }


    #Empty Recycle Bin if variable is not set or set to $true
    if($EmptyRecycleBin -eq $false) { 
        $timestamp = Get-Date
        $msg = "$timestamp - Not emptying recycle bin..."
        Write-Host $msg 
        $msg | Add-Content $logfile
    } else { 
        $timestamp = Get-Date
        $msg = "$timestamp - Emptying recycle bin..."
        Write-Host $msg 
        $msg | Add-Content $logfile
        Clear-RecycleBin -DriveLetter $DriveLetter -Force 
    }

    #Create custom hashtable with results.
    $returnHashTable = @{

        "JunkFound" = [math]::Round(($junkFound/ 1GB),2)

        "JunkRemoved" = [math]::Round(($junkRemoved/ 1GB),2)

        "JunkNotRemoved" = [math]::Round(($junkNotRemoved/ 1GB),2)

    }
    
    #Return that table as an object
    return new-object psobject -Property $returnHashTable

} #End Clear-DriveJunk function definition.





<# 
.NAME
    DiskCleaner by Jim Tyler, PowerShellEngineer.com
    Twitter: @PowerShellEng
    Github: @PowerShellEng
    YouTube: @PowerShellEng
#>







#Build Windows Forms UI Elements

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$DiskSlimmerForm = New-Object system.Windows.Forms.Form
$DiskSlimmerForm.ClientSize = New-Object System.Drawing.Point(447,335)
$DiskSlimmerForm.text = $FormTitleText
$DiskSlimmerForm.TopMost = $false
#$Icon = New-Object system.drawing.icon("http://www.powershellengineer.com/images/posh.png")
#$DiskSlimmerForm.icon = $Icon

$SelectDiskLabel = New-Object system.Windows.Forms.Label
$SelectDiskLabel.text = $SelectDiskLabelText
$SelectDiskLabel.AutoSize = $true
$SelectDiskLabel.width = 25
$SelectDiskLabel.height = 10
$SelectDiskLabel.location = New-Object System.Drawing.Point(20,19)
$SelectDiskLabel.Font = New-Object System.Drawing.Font('Microsoft Sans Serif',14,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))

$DriveComboBox = New-Object system.Windows.Forms.ComboBox
$DriveComboBox.width = 287
$DriveComboBox.height = 20
$DriveComboBox.location = New-Object System.Drawing.Point(137,16)
$DriveComboBox.Font = New-Object System.Drawing.Font('Microsoft Sans Serif',14)
$DriveComboBox.dropdownstyle = "DropDownList"

#Populate the ComboBox with Only Existing Drives
$drives = Get-Volume
foreach($drive in $drives) {
    if($null -ne $drive.DriveLetter) {
        $DriveComboBox.Items.Add($drive.DriveLetter)
    }
    if($drive.DriveLetter -eq "C") {
        $DriveComboBox.Text = "C" 
    }
}


$FreeSpaceLabel = New-Object system.Windows.Forms.Label
$FreeSpaceLabel.text = $FreeSpaceLabelText
$FreeSpaceLabel.AutoSize = $true
$FreeSpaceLabel.width = 25
$FreeSpaceLabel.height = 10
$FreeSpaceLabel.location = New-Object System.Drawing.Point(20,57)
$FreeSpaceLabel.Font = New-Object System.Drawing.Font('Microsoft Sans Serif',14)
$FreeSpaceLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#417505")

$TotalSpaceLabel = New-Object system.Windows.Forms.Label
$TotalSpaceLabel.text = $TotalSpaceLabelText
$TotalSpaceLabel.AutoSize = $true
$TotalSpaceLabel.width = 25
$TotalSpaceLabel.height = 10
$TotalSpaceLabel.location = New-Object System.Drawing.Point(20,91)
$TotalSpaceLabel.Font = New-Object System.Drawing.Font('Microsoft Sans Serif',14)

$FreeSpaceValue = New-Object system.Windows.Forms.Label
$FreeSpaceValue.text = [math]::Round(($c.SizeRemaining / 1GB),2)
$FreeSpaceValue.AutoSize = $true
$FreeSpaceValue.width = 25
$FreeSpaceValue.height = 10
$FreeSpaceValue.location = New-Object System.Drawing.Point(271,57)
$FreeSpaceValue.Font = New-Object System.Drawing.Font('Microsoft Sans Serif',14,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))
$FreeSpaceValue.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#417505")

$TotalSpaceValue = New-Object system.Windows.Forms.Label
$TotalSpaceValue.text = [math]::Round(($c.Size / 1GB),2)
$TotalSpaceValue.AutoSize = $true
$TotalSpaceValue.width = 25
$TotalSpaceValue.height = 10
$TotalSpaceValue.location = New-Object System.Drawing.Point(271,91)
$TotalSpaceValue.Font = New-Object System.Drawing.Font('Microsoft Sans Serif',14,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))

$JunkFoundLabel = New-Object system.Windows.Forms.Label
$JunkFoundLabel.text = $JunkFoundLabelText
$JunkFoundLabel.AutoSize = $true
$JunkFoundLabel.width = 25
$JunkFoundLabel.height = 10
$JunkFoundLabel.location = New-Object System.Drawing.Point(20,124)
$JunkFoundLabel.Font = New-Object System.Drawing.Font('Microsoft Sans Serif',14)
$JunkFoundLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d0021b")

$JunkFoundValue = New-Object system.Windows.Forms.Label
$JunkFoundValue.text = [math]::Round(($junkFound/ 1GB),2)
$JunkFoundValue.AutoSize = $true
$JunkFoundValue.width = 25
$JunkFoundValue.height = 10
$JunkFoundValue.location = New-Object System.Drawing.Point(271,125)
$JunkFoundValue.Font = New-Object System.Drawing.Font('Microsoft Sans Serif',14,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))
$JunkFoundValue.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d0021b")

$CleanDiskBtn = New-Object system.Windows.Forms.Button
$CleanDiskBtn.text = $CleanDiskBtnText 
$CleanDiskBtn.width = 402
$CleanDiskBtn.height = 39
$CleanDiskBtn.location = New-Object System.Drawing.Point(20,162)
$CleanDiskBtn.Font = New-Object System.Drawing.Font('Microsoft Sans Serif',14)

$SpaceCleanedLabel = New-Object system.Windows.Forms.Label
$SpaceCleanedLabel.text = $SpaceCleanedLabelText
$SpaceCleanedLabel.AutoSize = $true
$SpaceCleanedLabel.width = 25
$SpaceCleanedLabel.height = 10
$SpaceCleanedLabel.location = New-Object System.Drawing.Point(20,218)
$SpaceCleanedLabel.Font = New-Object System.Drawing.Font('Microsoft Sans Serif',14)
$SpaceCleanedLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#417505")

$SpaceCleanedValue = New-Object system.Windows.Forms.Label
$SpaceCleanedValue.text = "0GB"
$SpaceCleanedValue.AutoSize = $true
$SpaceCleanedValue.width = 25
$SpaceCleanedValue.height = 10
$SpaceCleanedValue.location = New-Object System.Drawing.Point(271,219)
$SpaceCleanedValue.Font = New-Object System.Drawing.Font('Microsoft Sans Serif',14,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))
$SpaceCleanedValue.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#417505")

$LogFileLabel = New-Object system.Windows.Forms.Label
$LogFileLabel.text = $LogFileLabelText
$LogFileLabel.AutoSize = $true
$LogFileLabel.width = 25
$LogFileLabel.height = 10
$LogFileLabel.location = New-Object System.Drawing.Point(20,254)
$LogFileLabel.Font = New-Object System.Drawing.Font('Microsoft Sans Serif',14)
$LogFileLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#000000")

$CreditLabel = New-Object system.Windows.Forms.Label
$CreditLabel.text = $CreditLabelText
$CreditLabel.AutoSize = $true
$CreditLabel.width = 25
$CreditLabel.height = 10
$CreditLabel.location = New-Object System.Drawing.Point(24,298)
$CreditLabel.Font = New-Object System.Drawing.Font('Microsoft Sans Serif',9)
$CreditLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#9b9b9b")

$DiskSlimmerForm.controls.AddRange(@($SelectDiskLabel,$DriveComboBox,$FreeSpaceLabel,$TotalSpaceLabel,$FreeSpaceValue,$TotalSpaceValue,$JunkFoundLabel,$JunkFoundValue,$CleanDiskBtn,$SpaceCleanedLabel,$SpaceCleanedValue,$LogFileLabel,$CreditLabel))

#Assess drive sizes and total up junk that can be cleared
$NewDriveLetter = $DriveComboBox.Text  
$LogFileLabel.text = "Analyzing drives..."
#Hide-Console 
$GetDriveJunk = Get-DriveJunk -DriveLetter $NewDriveLetter
$JunkFoundValue.text = $GetDriveJunk.JunkFound
$LogFileLabel.text = "Log File Located: $logfile"


$CleanDiskBtn.Add_Click({  

    #Show-Console
    $LogFileLabel.text = "Cleaning drive..."

    $BrowserCheck = Select-BrowserProcesses

    if($BrowserCheck -eq $false) {
        Write-Host "Browsers are not running... proceeding with disk cleanup..."
        $NewDriveLetter = $DriveComboBox.Text  
        $ClearDriveJunk = Clear-DriveJunk -DriveLetter $NewDriveLetter
        $SpaceCleanedValue.text = $ClearDriveJunk.JunkRemoved
        #Hide-Console 
        $LogFileLabel.text = "Log File Located: $logfile"
        #Re-check the junk size after the fact
        $GetDriveJunk = Get-DriveJunk -DriveLetter $NewDriveLetter
        $JunkFoundValue.text = $GetDriveJunk.JunkFound

    } else {
        Write-Host "Browsers are running... notifying user..."
        $LogFileLabel.text = "Please close all web browsers and try again."

    }

})

$DriveComboBox.Add_SelectedIndexChanged({
    $GetDriveJunk = Get-DriveJunk -DriveLetter $NewDriveLetter
    $JunkFoundValue.text = $GetDriveJunk.JunkFound
})

#region Logic 
<# 
.NAME
    DiskCleaner by Jim Tyler, PowerShellEngineer.com
    Twitter: @PowerShellEng
    Github: @PowerShellEng
    YouTube: @PowerShellEng
#>
#endregion

[void]$DiskSlimmerForm.ShowDialog()