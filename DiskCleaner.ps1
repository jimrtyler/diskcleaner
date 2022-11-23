<# 
.NAME
    DiskCleaner by Jim Tyler, PowerShellEngineer.com
    Twitter: @PowerShellEng
    Github: @PowerShellEng
    YouTube: @PowerShellEng
#>

#Define default log location
$LogFile = "C:\temp\diskcleaner.log"


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

#Import Custom Module with Clear Disk Functions
Import-Module .\ClearDiskJunk\ClearDiskJunk.psm1

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



#Function to determine if browsers are running
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

#Hide the console before GUI loads while drives are being assessed. 
Hide-Console 
$GetDriveJunk = Clear-DriveJunk -DriveLetter $NewDriveLetter -ActuallyDeleteFiles $false -LogFile $LogFile
$JunkFoundValue.text = $GetDriveJunk.JunkFound
$LogFileLabel.text = "Log File Located: $logfile"


$CleanDiskBtn.Add_Click({  

    #Show-Console
    $LogFileLabel.text = "Cleaning drive..."

    $BrowserCheck = Select-BrowserProcesses

    if($BrowserCheck -eq $false) {
        #Browsers are not running, so clean the disk.
        $NewDriveLetter = $DriveComboBox.Text  
        $ClearDriveJunk = Clear-DriveJunk -DriveLetter $NewDriveLetter -ActuallyDeleteFiles $true -LogFile $LogFile
        $SpaceCleanedValue.text = $ClearDriveJunk.JunkRemoved

        #Reset the Log File Label to the log file location (at this point, it says Cleaning drive...)
        $LogFileLabel.text = "Log File Located: $LogFile"

        #Reset drive free space label
        $drive = Get-Volume -DriveLetter $NewDriveLetter
        $FreeSpaceValue.text = [math]::Round(($drive.SizeRemaining / 1GB),2)

    } else {
        Write-Host "Browsers are running... notifying user..."
        $LogFileLabel.text = "Please close all web browsers and try again."

    }

})

$DriveComboBox.Add_SelectedIndexChanged({
    #Reset drive free space label
    $drive = Get-Volume -DriveLetter $DriveComboBox.Text  
    $FreeSpaceValue.text = [math]::Round(($drive.SizeRemaining / 1GB),2)
    $TotalSpaceValue.text = [math]::Round(($drive.Size / 1GB),2)

    #Calculate the junk on the newly selected drive
    $GetDriveJunk = Clear-DriveJunk -DriveLetter $DriveComboBox.Text -ActuallyDeleteFiles $false -LogFile "C:\temp\diskcleaner.log"
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