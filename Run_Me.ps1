#prompts for creds
$cr = Get-Credential 
echo = " "

#gets script directory
$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path

#creates results folder in script directory
New-Item -Path "$ScriptDir" -Name "Results" -ItemType "directory" -ErrorAction SilentlyContinue | Out-Null

#starts winrm on MIP if not started
$servicename = 'winrm'
$arrservices = Get-Service -Name $servicename
if ( $arrservices.Status -ne 'Running' )
    {
    net start winrm
    }

#Reads IP list, then runs adds ip to trusted host if its alive, then runs baseline.ps1 script against ip.  The script will then transfer files to MIP, and delete files on target
Get-Content "$ScriptDir\put_ips_here.txt" | ForEach-Object {
    if (Test-Connection $_ -Quiet -ErrorAction SilentlyContinue)
    {
        New-Item -Path "$ScriptDir\Results" -Name "$_" -ItemType "directory" -ErrorAction SilentlyContinue | Out-Null
        echo "- Collecting baseline for $_ "
        Set-Item WSMan:\localhost\Client\TrustedHosts -Value "$_" -Force;
        Invoke-Command -ComputerName "$_" -FilePath $ScriptDir\Baseline.ps1 -Credential $cr;
        echo "     DONE Collecting Info.  Transfer Started"
        $Session = New-PSSession -ComputerName "$_" -Credential $cr;
        $hosta = Invoke-Command -ComputerName "$_" -ScriptBlock {hostname} -Credential $cr;
        Copy-Item "c:\temp\$hosta" -Destination "$ScriptDir\Results\$_" -FromSession $Session -Recurse -ErrorAction SilentlyContinue;
        echo "     Files saved to MIP at $ScriptDir\Results\$_\";
        echo "     Deleting temp files on $_";
        Invoke-Command -ComputerName "$_" -ScriptBlock { Remove-Item -Path "c:\temp\$env:computername" -Recurse } -Credential $cr;
        echo "     Clearing TrustedHost IP from MIP";
        clear-Item WSMan:\localhost\Client\TrustedHosts -Force;
        echo "------------DONE WITH $_ ------------"
        echo " "
    }
    else
    {
        echo "*** $_ is not responding. ***"
        echo " "
        echo $_ >> $ScriptDir\Results\bad_ips.txt
    }
} 