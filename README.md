
<img src="https://github.com/user-attachments/assets/5737f6ae-9f7d-4ffa-a25b-7c84c5e9366b" width="400">

# DiskCleaner by Jim Tyler

**Author**: Jim Tyler  
**Twitter**: [@jimrtyler](https://twitter.com/jimrtyler)  
**GitHub**: [@jimrtyler](https://github.com/jimrtyler)  
**YouTube**: [@PowerShellEngineer](https://www.youtube.com/@PowerShellEngineer)

---

## Overview

DiskCleaner is a user-friendly PowerShell GUI script designed to analyze and clean up unnecessary files on your system, freeing up valuable disk space. It leverages PowerShell's capabilities with Windows Forms to provide an interactive, graphical interface, making disk cleanup tasks accessible even to non-technical users.

---

## One Liner Usage
1. Open PowerShell as Administrator
2. Run this command:
   ```powershell
   IEX(Invoke-WebRequest 'https://raw.githubusercontent.com/jimrtyler/diskcleaner/refs/heads/main/DiskCleanerStandalone.ps1'); Clear-DriveJunk -DriveLetter "C" -ActuallyDeleteFiles $true -LogFile ".\diskcleaner.log"

## Usage

1. Open PowerShell as Administrator.
2. Run the script:
   ```powershell
   .\DiskCleaner.ps1

---

## Features

- **Interactive GUI**: Intuitive Windows Forms interface for easy use.
- **Drive Selection**: Select any available drive on your system for analysis.
- **Space Analysis**: Display total and free space of the selected drive.
- **Junk File Detection**: Calculate and display the size of unnecessary files that can be removed.
- **Disk Cleaning**: Remove unnecessary files with a single button click.
- **Logging**: All actions and details are logged to a file for transparency.
- **Browser Detection**: Prevent cleanup if browsers are running to avoid potential data loss.

---

## Prerequisites

- **PowerShell Version**: 5.1 or later
- **Operating System**: Windows
- **Modules**: Ensure `ClearDiskJunk.psm1` is in the same directory as the script.

---

## Installation

1. Clone or download the repository to your local machine:
   ```bash
   git clone https://github.com/jimrtyler/DiskCleaner.git

--


