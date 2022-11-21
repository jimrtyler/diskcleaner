<# 
.NAME
    DiskCleaner Module by Jim Tyler, PowerShellEngineer.com
    Twitter: @PowerShellEng
    Github: @PowerShellEng
    YouTube: @PowerShellEng
#>


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

#Export Module Member
Export-ModuleMember -Function 'Clear-DiskJunk'
Export-ModuleMember -Function 'Get-DriveJunk'
Export-ModuleMember -Function 'Select-BrowserProcesses'