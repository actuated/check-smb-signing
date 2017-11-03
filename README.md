# check-smb-signing
Shell script to automate running Nmap's smb-security-mode.nse or lgandx's RunFinger.py and parse results into counts and lists of hosts that have message signing disabled, supported, and required (or true and false for RunFinger).

# Usage
```
./check-smb-signing.sh [tool] [input options] [--out-dir [output directory]] [--host-discovery]
```
* Tool options (must choose one):
  - **--finger** can be used to select lgandx's RunFinger.py. The file location is set with the `varRunFingerLocation` variable near the beginning of the script, or it can be set with the **--finger-path [path]** option.
  - **--nmap** can be used to select Nmap's smb-security-mode.nse.
* Input options (must choose one):
  - The script will take an address range or list of target hosts and perform an `nmap -sL` list scan against it to break it down into hosts, so you can use Nmap-style ranges to supply inputs for RunFinger.py if you want.
    - **-a [address/range]** can be used to specify an address (why?) or address range to scan.
    - **-f [file]** can be used to specify a file containing target hosts to scan.
  - **-r [file]** can be used to provide a file containing results from a scan you did separately with Nmap's smb-security-mode.nse (stdout) or RunFinger.py (-g grepable output or stdout). No scan for SMB signing will be run, results will just be parsed.
* Output options
  - The default output directory is `csmbs-YMDHM/`.
  - **--out-dir [path]** can be used to specify a different output directory.
  - Output files will include:
    - csmbs-count-HH-MM.txt - Output file with the color counts created by the script.
    - csmbs-parsed-HH-MM.txt - Output file with '[host]   [SMB signing value]' results.
    - csmbs-scan-HH-MM.txt - RunFinger.py or Nmap smb-security-mode.nse scan results. Not includes when you use **-r** to parse your own scan results file.
    - hosts-signing-[value].txt - A list of hosts for each SMB signing value (true or false for RunFinger.py and disabled, supported, or required for the NSE. Only created when there are applicable hosts.
* **--host-discovery** - Optionally run an 'nmap -sn' host discovery scan against **-a** or **-f** targets before running the NSE or RunFinger.py against them.
