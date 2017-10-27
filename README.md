# check-smb-signing
Shell script to automate running Nmap's smb-security-mode.nse and parse results into counts and lists of hosts that have message signing disabled, supported, and required.

# Usage
```
./check-smb-signing.sh [input mode] [input parameter] [--out-dir [output directory]]
```
* Input options
  - **-f [file]** can be used to specify a file containing hosts to scan with `nmap --script smb-security-mode.nse`. This file will be used as the `-iL` input file for `nmap`.
  - **-a [address range]** can be used to specify an address range to scan with `nmap --script smb-security-mode.nse`'. The provide address range will be used as the target specification for `nmap`.
  - **-r [file]** can be used to skip scanning and simply parsed a text file already contain terminal output of `nmap --script smb-security-mode.nse`. Meant to be used if you already ran the scan separately. Needs results without hostname resultion (`nmap -n ...`).
  - Only one input mode can be specified.
* Output options
  - Multiple files are written to an output directory, which is **check-smb-signing-YY-MM-DD-HH-MM** by default.
  - **--out-dir [directory]** can be used to specify an output directory of your choosing.
* Output files
  - **check-smb-signing-count-HH-MM.txt** records the number and percentage count shown by the script.
  - **check-smb-signing-parsed-HH-MM.txt** contains each `ip   message signing: [value]` result.
  - **check-smb-signing-scan-HH-MM.txt** records the `nmap --script smb-security-mode.nse` output.
  - **hosts-singing-disabled.txt** lists each IP with SMB signing disabled.
  - **hosts-signing-required.txt** lists each IP with SMB signing required.
  - **hosts-signing-supported.txt** lists each IP with SMB signing supported/enabled but not required.
  
  # Examples
```
./check-smb-signing.sh --out-dir test -f smb-hosts.txt 

=================[ check-smb-signing.sh - Ted R (github: actuated) ]=================

Note: test/ exists. Prior output files may be overwritten.
Press Enter to continue...

Nmap smb-security-mode.nse scan starting against smb-hosts.txt at 09:21
Nmap smb-security-mode.nse scan completed at 09:21

Parsing results...

=====================================[ results ]=====================================

 Total SMB Hosts: 		 2 

 Signing Required: 		 0 	 0% 
 Supported, not Required: 	 0 	 0% 
 Signing Disabled: 		 2 	 100% 

=======================================[ fin ]=======================================
```
```
./check-smb-signing.sh --out-dir test2 -r nmap-scan.txt 

=================[ check-smb-signing.sh - Ted R (github: actuated) ]=================

Parsing results...

=====================================[ results ]=====================================

 Total SMB Hosts: 		 74 

 Signing Required: 		 50 	 67.5% 
 Supported, not Required: 	 14 	 18.9% 
 Signing Disabled: 		 10 	 13.5% 

=======================================[ fin ]=======================================
```
