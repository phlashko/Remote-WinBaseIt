Step 1:  Download 4 files and place in single directory

Step 2:  Read ReadMe.txt

--------------------------------------------------------------

To manualy baseline:
   - run baseline.ps1 on target box with an admin powershell prompt.  Results will be saved to c:\temp\<target hostname>

To remotely baseline:
   - Add ips to put_ips_here.txt
   - Run Run_me.ps1 from an admin powershell prompt
   - Enter credentials for target host.  Please note, the creds you enter here will be used for all ips in put_ips_here.txt
