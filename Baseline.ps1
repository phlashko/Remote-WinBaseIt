# creates temp folder and hostname folder
$a = hostname
New-Item -Path "c:\" -Name "temp" -ItemType "directory" -ErrorAction SilentlyContinue | Out-Null
New-Item -Path "c:\temp" -Name "$a" -ItemType "directory" -ErrorAction SilentlyContinue | Out-Null
$temppath = "c:\temp\$a"

#systeminfo - DONE
echo "     Getting Date, Time, and SystemInfo"
Get-Date > $temppath\systeminfo.txt | Out-Null
systeminfo >> $temppath\systeminfo.txt | Out-Null

#Audit Policy - DONE
echo "     Getting Audit Policy"
auditpol /get /category:* > $temppath\auditpolicy.txt | Out-Null

#Network Settings  - DONE
echo "     Getting Network settings"
ipconfig /all > $temppath\ipconfig.txt | Out-Null
arp -a > $temppath\arp.txt | Out-Null
route print > $temppath\route.txt | Out-Null
netstat -bano > $temppath\netstat.txt | Out-Null

#Processes - Done
echo "     Getting running processes"
gwmi win32_process |select processname,ProcessID,ParentProcessID,CommandLine,@{e={$_.GetOwner().User}} | Sort processname > $temppath\process_list.txt | Out-Null

#services - Done
echo "     Getting Services"
Get-Service > $temppath\services.txt | Out-Null

#Users - Done
echo "     Getting User List"
net users > $temppath\users.txt | Out-Null

#Firewall Rules - Done
echo "     Getting Firewall Rules"
netsh advfirewall firewall show rule name = all > $temppath\firewall_rules.txt | Out-Null

#prefetch - Done
echo "     Getting Prefetch Directory Listing"
Get-ChildItem C:\Windows\Prefetch | sort > $temppath\prefetch_listing.txt | Out-Null

#Installed Apps - Done
echo "     Getting Installed Applications"
$PATHS = @("HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
           "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")
$SOFTWARE = "SOFTWARE_NAME"
$installapp = ForEach ($path in $PATHS) {
                Get-ChildItem -Path $path |
                    ForEach { Get-ItemProperty $_.PSPath } |
                    Select-Object -Property DisplayName,DisplayIcon,DisplayVersion,Publisher,InstallDate,InstallSource,InstallLocation,Version |
                    Where-Object {$_.displayname -NE $null -or $_.DisplayIcon -NE $null -or $_.InstallLocation -NE $null }
              }
$installapp | Sort-Object DisplayName > $temppath\installed_apps.txt

#Startup Apps - Done
echo "     Getting Startup Applications"
Get-WmiObject Win32_StartupCommand | select-object -property name,command,location | Sort-Object Name | Format-List > $temppath\startup_apps.txt | Out-Null

#Scheduled Tasks - Done
echo "     Getting Scheduled Tasks"
schtasks /query /FO list /v > $temppath\schedule_tasks.txt | Out-Null

#Drives (Logical / Physical) - Done
echo "     Getting Drive, and Share information"
$DriveType = @{
  Name = 'DriveType'
  Expression = {
    # property is an array, so process all values
    $value = $_.DriveType
    
    switch([int]$value)
      {
        0          {'Unknown'}
        1          {'No Root Directory'}
        2          {'Removable Disk'}
        3          {'Local Disk'}
        4          {'Network Drive'}
        5          {'Compact Disc'}
        6          {'RAM Disk'}
        default    {"$value"}
      }
      
  }  
}
Get-WmiObject -Class Win32_logicaldisk | Select-Object -Property DeviceID, $DriveType, VolumeName, @{L='FreeSpaceGB';E={"{0:N2}" -f ($_.FreeSpace /1GB)}}, @{L="Capacity";E={"{0:N2}" -f($_.Size/1GB)}}, ProviderName > $temppath\drives.txt | Out-Null
net share > $temppath\net_shares.txt | Out-Null

#Dir Walk c:\windows\system32
echo "     Getting Dir Walk of System32"
Get-ChildItem C:\Windows\System32 -Recurse > $temppath\dir_system32.txt | Out-Null

#Windows Defender Files
echo "     Getting Windows Defender Info Files"
cmd /c "c:\Program Files\Windows Defender\MpCmdRun.exe" -GetFiles | Out-Null
Copy-Item  -Path "C:\ProgramData\Microsoft\Windows Defender\Support\MpSupportFiles.cab" -Destination "C:\Temp\$a\Win_Defender.cab" | Out-Null