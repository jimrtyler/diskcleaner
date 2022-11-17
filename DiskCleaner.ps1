<# 
.NAME
    DiskCleaner by Jim Tyler, PowerShellEngineer.com
    Twitter: @PowerShellEng
#>

#Define Log File Location
$logfile = "C:\temp\diskslimmer.log"

# .Net methods for hiding/showing the console in the background 
Add-Type -Name Window -Namespace Console -MemberDefinition ' [DllImport("Kernel32.dll")] public static extern IntPtr GetConsoleWindow(); [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow); ' 

#Check the C Drive - this is the default drive to be checked. Users can change it in the dropdown combobox
$c = Get-Volume -DriveLetter C

function Check-Browsers() {
    $runningCount = 0
    if(Get-Process | ? {$_.ProcessName -like "*Edge*"}) { $runningCount++ }
    if(Get-Process | ? {$_.ProcessName -like "*Chrome*"}) { $runningCount++ }
    if(Get-Process | ? {$_.ProcessName -like "*Firefox*"}) { $runningCount++ }
    if(Get-Process | ? {$_.ProcessName -like "*Opera*"}) { $runningCount++ }
    if(Get-Process | ? {$_.ProcessName -like "*Iexplore*"}) { $runningCount++ }
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


#Function to Hide the PowerShell Console Behind the Windows Forms GUI
function Hide-Console { 
	$consolePtr = [Console.Window]::GetConsoleWindow() 
	#0 hide 
	[Console.Window]::ShowWindow($consolePtr, 0) 
} 

#Function to Calculate Drive Size and Junk
function Assess-Drives() {
    param(
        $DriveLetter
    )

    #Building the drive string; the environment has an issue when you try to echo a string with the value of 
    $colon = ":"
    $DriveString = "$DriveLetter$colon"
    
    #Paths array - paths of directories and log files that build up over time and need to be cleared. 
    $pathsToClear = @("C:\WINDOWS\SoftwareDistribution\Download",
    "$DriveString\WINDOWS\winsxs\backup",
    "$DriveString\WINDOWS\Installer\$PatchCache$",
    #"$DriveString\WINDOWS\ime\IMEJP",
    #"$DriveString\WINDOWS\system32\ime\IMEJP",
    #"$DriveString\WINDOWS\SysWOW64\ime\IMEJP",
    #"$DriveString\WINDOWS\ime\IMEKR",
    #"$DriveString\WINDOWS\system32\ime\IMEKR",
    #"$DriveString\WINDOWS\SysWOW64\ime\IMEKR",
    #"$DriveString\WINDOWS\ime\IMETC",
    #"$DriveString\WINDOWS\system32\ime\IMETC",
    #"$DriveString\WINDOWS\SysWOW64\ime\IMETC",
    "$DriveString\WINDOWS\help",
    "$DriveString\WINDOWS\Web\Wallpaper",
    "$DriveString\Windows\Installer",
    "$DriveString\Windows\Logs\WindowsUpdate",
    "$DriveString\Windows\Logs\waasmediccapsule",
    "$DriveString\Windows\Logs\waasmedic",
    "$DriveString\Windows\Logs\SIH",
    "$DriveString\Windows\Logs\NetSetup",
    "$DriveString\Windows\Logs\MoSetup",
    "$DriveString\Windows\Logs\MeasuredBoot",
    "$DriveString\Windows\Logs\DPX",
    "$DriveString\Windows\Logs\DISM",
    "$DriveString\Windows\Logs\CBS",
    "$DriveString\Windows\Logs\StorGroupPolicy.log",
    "$DriveString\Windows\System32\CatRoot2\dberr.txt",
    "$DriveString\Windows\debug",
    "$DriveString\Windows\security\logs\scecomp.old",
    "$DriveString\Windows\security\logs\scecomp.log",
    "$DriveString\Windows\SysWOW64\Gms.log",
    "$DriveString\Windows\SharedPCSetup.log",
    "$DriveString\Windows\stuperr.log",
    "$DriveString\Windows\setupact.log",
    "$DriveString\Windows\PFRO.log",
    "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*",
    "$env:LOCALAPPDATA\Microsoft\Terminal Server Client\Cache",
    "$DriveString\Windows\system32\FNTCACHE.DAT",
    "$DriveString\Windows\Temp",
    "$env:LOCALAPPDATA\Temp",
    "$env:LOCALAPPDATA\Microsoft\Windows\INetCache",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data"
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache")




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

    #Make sure the log location label is set again (in case it was overwritten by an error message)
    $LogFileLabel.text               = "Log File Located: $logfile"

    #Set the junk found size in the label
    $JunkFoundValue.text = [math]::Round(($junkFound/ 1GB),2)

}#End Assess-Drives function Declaration


function Slim-Drive() {
    param(
        $DriveLetter
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

    $pathsToClear = @("C:\WINDOWS\SoftwareDistribution\Download",
    "$DriveString\WINDOWS\winsxs\backup",
    "$DriveString\WINDOWS\Installer\$PatchCache$",
    #"C:\WINDOWS\ime\IMEJP",
    #"C:\WINDOWS\system32\ime\IMEJP",
    #"C:\WINDOWS\SysWOW64\ime\IMEJP",
    #"C:\WINDOWS\ime\IMEKR",
    #"C:\WINDOWS\system32\ime\IMEKR",
    #"C:\WINDOWS\SysWOW64\ime\IMEKR",
    #"C:\WINDOWS\ime\IMETC",
    #"C:\WINDOWS\system32\ime\IMETC",
    #"C:\WINDOWS\SysWOW64\ime\IMETC",
    "$DriveString\WINDOWS\help",
    "$DriveString\WINDOWS\Web\Wallpaper",
    "$DriveString\Windows\Installer",
    "$DriveString\Windows\Logs\WindowsUpdate",
    "$DriveString\Windows\Logs\waasmediccapsule",
    "$DriveString\Windows\Logs\waasmedic",
    "$DriveString\Windows\Logs\SIH",
    "$DriveString\Windows\Logs\NetSetup",
    "$DriveString\Windows\Logs\MoSetup",
    "$DriveString\Windows\Logs\MeasuredBoot",
    "$DriveString\Windows\Logs\DPX",
    "$DriveString\Windows\Logs\DISM",
    "$DriveString\Windows\Logs\CBS",
    "$DriveString\Windows\Logs\StorGroupPolicy.log",
    "$DriveString\Windows\System32\CatRoot2\dberr.txt",
    "$DriveString\Windows\debug",
    "$DriveString\Windows\security\logs\scecomp.old",
    "$DriveString\Windows\security\logs\scecomp.log",
    "$DriveString\Windows\SysWOW64\Gms.log",
    "$DriveString\Windows\SharedPCSetup.log",
    "$DriveString\Windows\stuperr.log",
    "$DriveString\Windows\setupact.log",
    "$DriveString\Windows\PFRO.log",
    "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*",
    "$env:LOCALAPPDATA\Microsoft\Terminal Server Client\Cache",
    "$DriveString\Windows\system32\FNTCACHE.DAT",
    "$DriveString\Windows\Temp",
    "$env:LOCALAPPDATA\Temp",
    #"$env:LOCALAPPDATA\Microsoft\Windows\INetCache",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data"
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache")

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
                Get-ChildItem -Path $path -Include *.* -File -Recurse | foreach { Remove-Item -Path $_ -Force }

            } else {
                $timestamp = Get-Date
                $msg = "$timestamp - Deleting file: $path"
                Write-Host $msg 
                $msg | Add-Content $logfile
                $file = Get-ChildItem -Path $path -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum | Select-Object Sum, Count
                $junkFound += $file.Sum

                #Actually delete the file 
                Remove-Item -Path $path -Force
            }
            #end assessing if it's a directory
        } else {

            Write-Host "We can't seem to find $path"

        }
    }
    #Update UI with space cleaned
    $SpaceCleanedValue.text = [math]::Round(($junkFound/ 1GB),2)

    #Update log with cleaned space
    $spaceCleaned = [math]::Round(($junkFound/ 1GB),2)
    $timestamp = Get-Date
    $msg = "$timestamp - Space Cleaned: $spaceCleaned GB"
    Write-Host $msg 
    $msg | Add-Content $logfile

    #Assess current disk size after cleaning
    $timestamp = Get-Date
    $driveObj = Get-Volume -DriveLetter $DriveLetter
    $diskSize = [math]::Round(($driveObj.Size/ 1GB),2)
    $diskFreeSpace = [math]::Round(($driveObj.SizeRemaining/ 1GB),2)
    $msg = "$timestamp - Disk Size: $diskSize GB --- Disk Free Space: $diskFreeSpace GB"
    $msg | Add-Content $logfile

    #Empty Recycle Bin
    Clear-RecycleBin -DriveLetter $DriveLetter -Force

    #Make sure the log location label is set again (in case it was overwritten by an error message)
    $LogFileLabel.text               = "Log File Located: $logfile"

}


#Build Windows Forms UI Elements

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$DiskSlimmerForm                 = New-Object system.Windows.Forms.Form
$DiskSlimmerForm.ClientSize      = New-Object System.Drawing.Point(447,335)
$DiskSlimmerForm.text            = "Disk Cleaner by Jim Tyler (PowerShellEngineer.com)"
$DiskSlimmerForm.TopMost         = $false
#$Icon = New-Object system.drawing.icon("http://www.powershellengineer.com/images/posh.png")
#$DiskSlimmerForm.icon            = $Icon

$SelectDiskLabel                 = New-Object system.Windows.Forms.Label
$SelectDiskLabel.text            = "Select Disk:"
$SelectDiskLabel.AutoSize        = $true
$SelectDiskLabel.width           = 25
$SelectDiskLabel.height          = 10
$SelectDiskLabel.location        = New-Object System.Drawing.Point(20,19)
$SelectDiskLabel.Font            = New-Object System.Drawing.Font('Microsoft Sans Serif',14,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))

$DriveComboBox                   = New-Object system.Windows.Forms.ComboBox
$DriveComboBox.width             = 287
$DriveComboBox.height            = 20
$DriveComboBox.location          = New-Object System.Drawing.Point(137,16)
$DriveComboBox.Font              = New-Object System.Drawing.Font('Microsoft Sans Serif',14)
$DriveComboBox.dropdownstyle     = "DropDownList"

#Populate the ComboBox with Only Existing Drives
$drives = Get-Volume
foreach($drive in $drives) {
    if($drive.DriveLetter -ne $null) {
        $DriveComboBox.Items.Add($drive.DriveLetter)
    }
    if($drive.DriveLetter -eq "C") {
        $DriveComboBox.Text = "C" 
    }
}


$FreeSpaceLabel                  = New-Object system.Windows.Forms.Label
$FreeSpaceLabel.text             = "Free Space (GB): "
$FreeSpaceLabel.AutoSize         = $true
$FreeSpaceLabel.width            = 25
$FreeSpaceLabel.height           = 10
$FreeSpaceLabel.location         = New-Object System.Drawing.Point(20,57)
$FreeSpaceLabel.Font             = New-Object System.Drawing.Font('Microsoft Sans Serif',14)
$FreeSpaceLabel.ForeColor        = [System.Drawing.ColorTranslator]::FromHtml("#417505")

$TotalSpaceLabel                 = New-Object system.Windows.Forms.Label
$TotalSpaceLabel.text            = "Total Space (GB): "
$TotalSpaceLabel.AutoSize        = $true
$TotalSpaceLabel.width           = 25
$TotalSpaceLabel.height          = 10
$TotalSpaceLabel.location        = New-Object System.Drawing.Point(20,91)
$TotalSpaceLabel.Font            = New-Object System.Drawing.Font('Microsoft Sans Serif',14)

$FreeSpaceValue                  = New-Object system.Windows.Forms.Label
$FreeSpaceValue.text             = [math]::Round(($c.SizeRemaining / 1GB),2)
$FreeSpaceValue.AutoSize         = $true
$FreeSpaceValue.width            = 25
$FreeSpaceValue.height           = 10
$FreeSpaceValue.location         = New-Object System.Drawing.Point(271,57)
$FreeSpaceValue.Font             = New-Object System.Drawing.Font('Microsoft Sans Serif',14,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))
$FreeSpaceValue.ForeColor        = [System.Drawing.ColorTranslator]::FromHtml("#417505")

$TotalSpaceValue                 = New-Object system.Windows.Forms.Label
$TotalSpaceValue.text            = [math]::Round(($c.Size / 1GB),2)
$TotalSpaceValue.AutoSize        = $true
$TotalSpaceValue.width           = 25
$TotalSpaceValue.height          = 10
$TotalSpaceValue.location        = New-Object System.Drawing.Point(271,91)
$TotalSpaceValue.Font            = New-Object System.Drawing.Font('Microsoft Sans Serif',14,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))

$JunkFoundLabel                  = New-Object system.Windows.Forms.Label
$JunkFoundLabel.text             = "Junk Found (GB):"
$JunkFoundLabel.AutoSize         = $true
$JunkFoundLabel.width            = 25
$JunkFoundLabel.height           = 10
$JunkFoundLabel.location         = New-Object System.Drawing.Point(20,124)
$JunkFoundLabel.Font             = New-Object System.Drawing.Font('Microsoft Sans Serif',14)
$JunkFoundLabel.ForeColor        = [System.Drawing.ColorTranslator]::FromHtml("#d0021b")

$JunkFoundValue                  = New-Object system.Windows.Forms.Label
$JunkFoundValue.text             = [math]::Round(($junkFound/ 1GB),2)
$JunkFoundValue.AutoSize         = $true
$JunkFoundValue.width            = 25
$JunkFoundValue.height           = 10
$JunkFoundValue.location         = New-Object System.Drawing.Point(271,125)
$JunkFoundValue.Font             = New-Object System.Drawing.Font('Microsoft Sans Serif',14,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))
$JunkFoundValue.ForeColor        = [System.Drawing.ColorTranslator]::FromHtml("#d0021b")

$CleanDiskBtn                    = New-Object system.Windows.Forms.Button
$CleanDiskBtn.text               = "Clean Disk *Warning - Deletes Files*"
$CleanDiskBtn.width              = 402
$CleanDiskBtn.height             = 39
$CleanDiskBtn.location           = New-Object System.Drawing.Point(20,162)
$CleanDiskBtn.Font               = New-Object System.Drawing.Font('Microsoft Sans Serif',14)

$Label2                          = New-Object system.Windows.Forms.Label
$Label2.text                     = "Space Cleaned (GB): "
$Label2.AutoSize                 = $true
$Label2.width                    = 25
$Label2.height                   = 10
$Label2.location                 = New-Object System.Drawing.Point(20,218)
$Label2.Font                     = New-Object System.Drawing.Font('Microsoft Sans Serif',14)
$Label2.ForeColor                = [System.Drawing.ColorTranslator]::FromHtml("#417505")

$SpaceCleanedValue               = New-Object system.Windows.Forms.Label
$SpaceCleanedValue.text          = "0GB"
$SpaceCleanedValue.AutoSize      = $true
$SpaceCleanedValue.width         = 25
$SpaceCleanedValue.height        = 10
$SpaceCleanedValue.location      = New-Object System.Drawing.Point(271,219)
$SpaceCleanedValue.Font          = New-Object System.Drawing.Font('Microsoft Sans Serif',14,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))
$SpaceCleanedValue.ForeColor     = [System.Drawing.ColorTranslator]::FromHtml("#417505")

$LogFileLabel                    = New-Object system.Windows.Forms.Label
$LogFileLabel.text               = "Log File Located: $logfile"
$LogFileLabel.AutoSize           = $true
$LogFileLabel.width              = 25
$LogFileLabel.height             = 10
$LogFileLabel.location           = New-Object System.Drawing.Point(20,254)
$LogFileLabel.Font               = New-Object System.Drawing.Font('Microsoft Sans Serif',14)
$LogFileLabel.ForeColor          = [System.Drawing.ColorTranslator]::FromHtml("#000000")

$Label1                          = New-Object system.Windows.Forms.Label
$Label1.text                     = "Script by Jim Tyler - PowerShellEngineer.com"
$Label1.AutoSize                 = $true
$Label1.width                    = 25
$Label1.height                   = 10
$Label1.location                 = New-Object System.Drawing.Point(24,298)
$Label1.Font                     = New-Object System.Drawing.Font('Microsoft Sans Serif',9)
$Label1.ForeColor                = [System.Drawing.ColorTranslator]::FromHtml("#9b9b9b")

$DiskSlimmerForm.controls.AddRange(@($SelectDiskLabel,$DriveComboBox,$FreeSpaceLabel,$TotalSpaceLabel,$FreeSpaceValue,$TotalSpaceValue,$JunkFoundLabel,$JunkFoundValue,$CleanDiskBtn,$Label2,$SpaceCleanedValue,$LogFileLabel,$Label1))

#Assess drive sizes and total up junk that can be cleared
$NewDriveLetter = $DriveComboBox.Text  
$LogFileLabel.text = "Analyzing drives..."
Hide-Console 
Assess-Drives -DriveLetter $NewDriveLetter
$LogFileLabel.text = "Log File Located: $logfile"


$CleanDiskBtn.Add_Click({  

    #Show-Console
    $LogFileLabel.text = "Cleaning drive..."

    $BrowserCheck = Check-Browsers

    if($BrowserCheck -eq $false) {
        Write-Host "Browsers are not running... proceeding with disk cleanup..."
        $NewDriveLetter = $DriveComboBox.Text  
        Slim-Drive -DriveLetter $NewDriveLetter
        #Hide-Console 
        $LogFileLabel.text = "Log File Located: $logfile"

    } else {
        Write-Host "Browsers are running... notifying user..."
        $LogFileLabel.text = "Please close all web browsers and try again."

    }

})

$DriveComboBox.Add_SelectedIndexChanged({
    $NewDriveLetter = $DriveComboBox.Text  
    Assess-Drives -DriveLetter $NewDriveLetter
})

#region Logic 

#endregion

[void]$DiskSlimmerForm.ShowDialog()