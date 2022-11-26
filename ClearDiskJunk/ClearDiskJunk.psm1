<#
 .Synopsis
  Clears unwanted temporary, cache, and log files. 

 .Description
  Iterates through a list of common temporary, cache, and log paths, assessing their size and
  forcibly removing them.

 .Parameter DriveLetter
  Mandatory string - drive letter of disk/volume to be assessed or cleared. Use the Get-Volume cmdlet to see your drive letters.

 .Parameter ActuallyDeleteFiles
  Mandatory boolean that can be set to $true or $false. If $true, files will actually be deleted.

 .Parameter LogFile
  Mandatory string - path to log file.

 .Example
   # Simplest usage of the function that does NOT delete files.
   Clear-DriveJunk -DriveLetter "C" -ActuallyDeleteFiles $false -LogFile "C:\temp\diskcleaner.log"

 .Example
   # Simplest usage of the function that DOES delete files.
   Clear-DriveJunk -DriveLetter "C" -ActuallyDeleteFiles $true -LogFile "C:\temp\diskcleaner.log"

 .Example
   # Deletes temporary, log, and cache files older than 30 days on drive C, storing log to C:\temp\delete.log
   Clear-DriveJunk -DriveLetter "C" -ActuallyDeleteFiles $true -LogFile "C:\temp\delete.log" -OlderThan -30 -EmptyRecycleBin $true
#>
<# 
.NAME
    DiskCleaner by Jim Tyler, PowerShellEngineer.com
    Twitter: @jimrtyler
    Github: @jimrtyler
    YouTube: @PowerShellEngineer
#>

function Clear-DriveJunk() {
    [CmdletBinding()]
    param(
        #Drive to be cleaned
        [Parameter(Position=0,mandatory=$true)]
        [string] $DriveLetter,

        #Mandatory - Decide if you want to actually delete files or not. If $true, it will delete. If not, it will just calculate what would have been deleted.
        [Parameter(Position=1,mandatory=$true)]
        [bool] $ActuallyDeleteFiles, 

        #Mandatory - LogFile Location ex. C:\temp\diskcleaner.log
        [Parameter(Position=2,mandatory=$true)]
        [string] $LogFile

    )

    #Write log that slimming has started...
    $timestamp = Get-Date
    $msg = "$timestamp - Clean attempt started for drive $DriveLetter ..."
    Write-Host $msg 
    $msg | Add-Content $LogFile

    #Assess current disk size
    $timestamp = Get-Date
    $driveObj = Get-Volume -DriveLetter $DriveLetter
    $diskSize = [math]::Round(($driveObj.Size/ 1GB),2)
    $diskFreeSpace = [math]::Round(($driveObj.SizeRemaining/ 1GB),2)
    $msg = "$timestamp - Disk Size: $diskSize GB --- Disk Free Space: $diskFreeSpace GB"
    $msg | Add-Content $LogFile

    #Building the drive string; the environment has an issue when you try to echo a string with the value of 
    $colon = ":"
    $DriveString = "$DriveLetter$colon"

    $pathsToClear = @("$DriveString\WINDOWS\SoftwareDistribution\Download","$DriveString\WINDOWS\winsxs\backup","$DriveString\WINDOWS\help","$DriveString\WINDOWS\Web\Wallpaper","$DriveString\Windows\Logs\WindowsUpdate","$DriveString\Windows\Logs\waasmediccapsule","$DriveString\Windows\Logs\waasmedic","$DriveString\Windows\Logs\SIH","$DriveString\Windows\Logs\NetSetup","$DriveString\Windows\Logs\MoSetup","$DriveString\Windows\Logs\MeasuredBoot","$DriveString\Windows\Logs\DPX","$DriveString\Windows\Logs\DISM","$DriveString\Windows\Logs\CBS","$DriveString\Windows\Logs\StorGroupPolicy.log","$DriveString\Windows\System32\CatRoot2\dberr.txt","$DriveString\Windows\debug","$DriveString\Windows\security\logs\scecomp.old","$DriveString\Windows\security\logs\scecomp.log","$DriveString\Windows\SysWOW64\Gms.log","$DriveString\Windows\SharedPCSetup.log","$DriveString\Windows\stuperr.log","$DriveString\Windows\setupact.log","$DriveString\Windows\PFRO.log","$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*","$env:LOCALAPPDATA\Microsoft\Terminal Server Client\Cache","$DriveString\Windows\system32\FNTCACHE.DAT","$DriveString\Windows\Temp","$env:LOCALAPPDATA\Temp","$env:LOCALAPPDATA\Microsoft\Edge\User Data","$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache") #"$DriveString\WINDOWS\Installer\$PatchCache$","$DriveString\Windows\Installer")                    #Script by Jim Tyler, PowerShellEngineer.com                                                

    Foreach ($path in $pathsToClear) {

        #Check if it exists
        if((Test-Path -Path $path) -eq $true) {

            #Write-Host "We found stuff at $path"

            #Check to see if the path is a directory. Calculating size of a directory vs. a file is different
            $isDir = (Get-Item $path) -is [System.IO.DirectoryInfo]
            if($isDir) {
                #Log if $path was a directory or not
                $timestamp = Get-Date
                $msg = "$timestamp - Path is a directory: $_"
                #Write-Host $msg 
                $msg | Add-Content $LogFile

                #Evaluate the files in the directory
                $dir = Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum | Select-Object Sum, Count
                $junkFound += $dir.Sum

                #Actually delete the contents of the folder
                Get-ChildItem -Path $path -Include *.* -File -Recurse | ForEach-Object {
                    
                    #Assess the size of the specific file before it is deleted.
                    $fileInDir = Get-ChildItem -Path $_ -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum | Select-Object Sum, Count

                    #Only delete if the $ActuallyDeleteFiles parameter is set to $true. This is a mandatory parameter.
                    if($ActuallyDeleteFiles -eq $true) { 
                        try {
                            Remove-Item -Path $_ -Force  
                        }
                        catch {
                            Write-Host "Unable to delete $_"
                        }    
                        
                    
                    }
                    
                    #Test if it was actually deleted or not, total the correct counter 
                    if((Test-Path -path $_) -eq $true) { 
                        #Log if file was not deleted
                        #$timestamp = Get-Date
                        #$msg = "$timestamp - Failed to delete: $_"
                        #Write-Host $msg 
                        #$msg | Add-Content $LogFile

                        #Total counter of size of files deleted
                        $junkNotRemoved += $fileInDir.Sum 
                    } else { 
                        #Log if file was deleted
                        #$timestamp = Get-Date
                        #$msg = "$timestamp - Successfully deleted: $_"
                        #Write-Host $msg 
                        #$msg | Add-Content $LogFile

                        #Total counter of size of files deleted
                        $junkRemoved += $fileInDir.Sum 
                    } 
                }

            } else {
                #Log if $path was a directory or not
                $timestamp = Get-Date
                $msg = "$timestamp - Path is a file: $_"
                #Write-Host $msg 
                $msg | Add-Content $LogFile
                #Evaluate the file
                $file = Get-ChildItem -Path $path -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum | Select-Object Sum, Count
                $junkFound += $file.Sum

                #Actually delete the file
                
                #Only delete if the $ActuallyDeleteFiles parameter is set to $true. This is a mandatory parameter.
                if($ActuallyDeleteFiles -eq $true) { 
                    try {
                        Remove-Item -Path $path -Force 
                    }
                    catch {
                        Write-Host "Unable to delete $path"
                    }
                    
                }

                #Test if it was actually deleted or not, total the correct counter 
                if((Test-Path -path $path) -eq $true) { 
                    #Write to the log file
                    #$timestamp = Get-Date
                    #$msg = "$timestamp - Failed to delete file: $path"
                    #Write-Host $msg 
                    #$msg | Add-Content $LogFile

                    #Total the size of the files not deleted
                    $junkNotRemoved += $junkFound
                } else { 
                    #Write to the log file
                    #$timestamp = Get-Date
                    #$msg = "$timestamp - Successfully deleted file: $path"
                    #Write-Host $msg 
                    #$msg | Add-Content $LogFile

                    #Total the size of the files deleted
                    $junkRemoved += $junkFound
                }
            }
            #end assessing if it's a directory
        } else {
            Write-Host "Not found: $path"
        }
    }


    #Remove all superseded versions of every component in component store. 
    #Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase

    #Empty Recycle Bin for specified drive.
    Clear-RecycleBin -DriveLetter $DriveLetter -Force 

    #If files were actually deleted, preserve the total. If not, set the JunkeRemoved being returned to zero
    #if($ActuallyDeleteFiles -eq $true) { $JunkRemovedReturn = [math]::Round(($junkRemoved/ 1GB),2) } else { $JunkRemovedReturn = "0" }

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
Export-ModuleMember -Function 'Clear-DriveJunk'




























<# 
.NAME
    DiskCleaner by Jim Tyler, PowerShellEngineer.com
    Twitter: @jimrtyler
    Github: @jimrtyler
    YouTube: @PowerShellEngineer
#>