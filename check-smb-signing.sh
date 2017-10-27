#!/bin/bash
# check-smb-signing.sh (v1.0)
# v1.0 - 10/26/2017 by Ted R (http://github.com/actuated)
# Script to run and parse SMB message signing results using Nmap's smb-security-mode.nse
varDateCreated="10/26/2017"
varDateLastMod="10/27/2017"

varYMDHM=$(date +%F-%H-%M)
varHM=$(date +%H-%M)
varTempScan="check-smb-signing-scan-$varHM.txt"
varTempParsed="check-smb-signing-parsed-$varHM.txt"
varTempCount="check-smb-signing-count-$varHM.txt"
varOutDir="check-smb-signing-$varYMDHM"
varInMode="N"
varTarget="N"
varCountInMode=0

# Function for providing help/usage text

function fnUsage {
  echo
  echo "=================[ check-smb-signing.sh - Ted R (github: actuated) ]================="
  echo
  echo "Script to run Nmap's smb-security-mode.nse against a file (-f) of targets or a range"
  echo "of addresses (-a), then parse results into a count of hosts with each message signing"
  echo "mode and separate files containing IPs for hosts with each message signing mode."
  echo
  echo "Created $varDateCreated, last modified $varDateLastMod."
  echo
  echo "======================================[ usage ]======================================"
  echo
  echo "./check-smb-signing.sh [input mode] [targets] [--out-dir [path]]"
  echo
  echo "Input Options (specify one):"
  echo
  echo "-f [target file]    Scan a file of targets. Will be used with Nmap's -iL option."
  echo
  echo "-a [target range]   Scan an IP range. Must include three '.' characters. Will be used"
  echo "                    as the target input for Nmap."
  echo
  echo "-r [file]           Skip scanning by providing a file with stdout results from Nmap's"
  echo "                    smb-security-mode NSE. Parsing is written to use the IP, so run"
  echo "                    Nmap with -n, or use this script to scan."
  echo
  echo "Output Options:"
  echo
  echo "--out-dir [path]    Optionally specify an output directory. The default is:"
  echo "                    ./check-smb-signing-YY-MM-DD-HH-MM/"
  echo
  echo "===================================[ file output ]==================================="
  echo
  echo "check-smb-signing-count-HH-MM.txt    Text file with color terminal output of counts."
  echo "check-smb-signing-parsed-HH-MM.txt   Each 'ip   message_signing: [value]' result."
  echo "check-smb-signing-scan-HH-MM.txt     Nmap smb-security-mode.nse output."
  echo "hosts-signing-disabled.txt           List of IPs with signing disabled."
  echo "hosts-signing-required.txt           List of IPs with signing required."
  echo "hosts-signing-supported.txt          List of IPs with signing enabled/supported but"
  echo "                                     not required."
  echo
  echo "Note: hosts-signing-[value].txt will only be created when applicable."
  echo
  exit
}

function fnScan {

  # Run Nmap depending on input mode

  echo
  varTimeNow=$(date +%H:%M)
  echo "Nmap smb-security-mode.nse scan starting against $varTarget at $varTimeNow"
  if [ "$varInMode" = "File" ]; then
    nmap -iL "$varTarget" -sS -Pn -n -p 445 --open --script smb-security-mode.nse > "$varOutDir/$varTempScan"
  elif [ "$varInMode" = "Address" ]; then
    nmap "$varTarget" -sS -Pn -n -p 445 --open --script smb-security-mode.nse > "$varOutDir/$varTempScan"
  fi
  varTimeNow=$(date +%H:%M)
  echo "Nmap smb-security-mode.nse scan completed at $varTimeNow"
}

function fnParse {

  if [ "$varInMode" = "Results" ]; then
    varScanResults="$varTarget"
  else
    varScanResults="$varOutDir/$varTempScan"
    varTarget="$varTempScan"
  fi

  # Make sure there are message_signing results to parse

  varCheckResults=$(grep message_signing "$varScanResults")
  if [ "$varCheckResults" = "" ]; then
    echo
    echo "Parsing Error: No message_signing results in $varTarget."
    echo
    exit
  fi

  echo
  echo "Parsing results..."

  # Create parsed file of 'ip   message_signing: [value]'

  echo > "$varOutDir/$varTempParsed"
  echo "=================[ check-smb-signing.sh - Ted R (github: actuated) ]=================" >> "$varOutDir/$varTempParsed"
  echo >> "$varOutDir/$varTempParsed"
  varThisLine=""
  varLastHost=""
  varStatus=""
  while read varThisLine; do
    varCheckForScanReport=$(echo "$varThisLine" | grep "Nmap scan report for")
    if [ "$varCheckForScanReport" != "" ]; then
      varLastHost=$(echo "$varThisLine" | awk '{print $5}')
    fi
    varCheckForVulnState=$(echo "$varThisLine" | grep "message_signing")
    if [ "$varCheckForVulnState" != "" ]; then
      varStatus=$(echo "$varThisLine" | awk '{print $2, $3}')
      echo -e "$varLastHost \t $varStatus" >> "$varOutDir/$varTempParsed"
    fi
  done < "$varScanResults"
  echo >> "$varOutDir/$varTempParsed"
  echo "=======================================[ fin ]=======================================" >> "$varOutDir/$varTempParsed"
  echo >> "$varOutDir/$varTempParsed"

  # Create counts

  varTotalHosts=$(grep message_signing "$varOutDir/$varTempParsed" | wc -l )
  varSigningRequired=$(grep required "$varOutDir/$varTempParsed" | wc -l )
  varSigningSupported=$(grep supported "$varOutDir/$varTempParsed" | wc -l )
  varSigningDisabled=$(grep disabled "$varOutDir/$varTempParsed" | wc -l)
  varPercentRequired=$(awk "BEGIN {print $varSigningRequired*100/$varTotalHosts}" | cut -c1-4)%
  varPercentSupported=$(awk "BEGIN {print $varSigningSupported*100/$varTotalHosts}" | cut -c1-4)%
  varPercentDisabled=$(awk "BEGIN {print $varSigningDisabled*100/$varTotalHosts}" | cut -c1-4)%

  echo
  echo "=====================================[ results ]====================================="
  echo
  echo -e "\033[1;37m Total SMB Hosts: \t\t $varTotalHosts \e[0m"
  echo
  echo -e "\033[33;32m Signing Required: \t\t $varSigningRequired \t $varPercentRequired \e[0m"
  echo -e "\033[33;33m Supported, not Required: \t $varSigningSupported \t $varPercentSupported \e[0m"
  echo -e "\033[33;31m Signing Disabled: \t\t $varSigningDisabled \t $varPercentDisabled \e[0m"

  echo > "$varOutDir/$varTempCount"
  echo "=================[ check-smb-signing.sh - Ted R (github: actuated) ]=================" >> "$varOutDir/$varTempCount"
  echo >> "$varOutDir/$varTempCount"
  echo -e "\033[1;37m Total SMB Hosts: \t\t $varTotalHosts \e[0m" >> "$varOutDir/$varTempCount" >> "$varOutDir/$varTempCount"
  echo >> "$varOutDir/$varTempCount"
  echo -e "\033[33;32m Signing Required: \t\t $varSigningRequired \t $varPercentRequired \e[0m" >> "$varOutDir/$varTempCount"
  echo -e "\033[33;33m Supported, not Required: \t $varSigningSupported \t $varPercentSupported \e[0m" >> "$varOutDir/$varTempCount"
  echo -e "\033[33;31m Signing Disabled: \t\t $varSigningDisabled \t $varPercentDisabled \e[0m" >> "$varOutDir/$varTempCount"
  echo  >> "$varOutDir/$varTempCount"
  echo "=======================================[ fin ]=======================================">> "$varOutDir/$varTempCount"
  echo  >> "$varOutDir/$varTempCount"

  # Create lists of hosts split by SMB signing value

  if [ "$varSigningDisabled" -gt "0" ]; then
    grep disabled "$varOutDir/$varTempParsed" | awk '{print $1}' | sort -V > "$varOutDir/hosts-signing-disabled.txt"
  fi

  if [ "$varSigningSupported" -gt "0" ]; then
    grep supported "$varOutDir/$varTempParsed" | awk '{print $1}' | sort -V > "$varOutDir/hosts-signing-supported.txt"
  fi

  if [ "$varSigningRequired" -gt "0" ]; then
    grep required "$varOutDir/$varTempParsed" | awk '{print $1}' | sort -V > "$varOutDir/hosts-signing-required.txt"
  fi

}

# Read options

while [ "$1" != "" ]; do
  case "$1" in
    -f )
      varInMode="File"
      let varCountInMode=varCountInMode+1
      shift
      varTarget="$1"
      ;;
    -a )
      varInMode="Address"
      let varCountInMode=varCountInMode+1
      shift
      varTarget="$1"
      ;;
    -r )
      varInMode="Results"
      let varCountInMode=varCountInMode+1
      shift
      varTarget="$1"
      ;;
    --out-dir )
      shift
      varOutDir="$1"
      ;;
    -h )
      fnUsage
      ;;
    * )
      echo
      echo "Error: Unrecognized argument."
      fnUsage
      ;;
  esac
  shift
done

# Check options

if [ $varCountInMode -gt 1 ]; then echo; echo "Error: More than one input mode specified."; fnUsage; fi

if [ "$varInMode" = "N" ]; then
  echo
  echo "Error: No input mode specified."
  fnUsage
elif [ "$varInMode" = "File" ] && [ ! -f "$varTarget" ]; then
  echo
  echo "Error: File specified with -f does not exist."
  fnUsage
elif [ "$varInMode" = "Address" ] && [ "$varTarget" = "" ]; then
  echo
  echo "Error: No address/range specified after -a."
  fnUsage
elif [ "$varInMode" = "Address" ]; then
  varCheckAddr=$(echo $varTarget | awk -F. '{print NF-1}')
  if [ "$varCheckAddr" != "3" ]; then
    echo
    echo "Error: '$varTarget' does not appear to be an IP address/range."
    fnUsage
  fi
elif [ "$varInMode" = "Results" ] && [ ! -f "$varTarget" ]; then
  echo
  echo "Error: File specified with -r does not exist."
  fnUsage
fi

echo
echo "=================[ check-smb-signing.sh - Ted R (github: actuated) ]================="

if [ -d "$varOutDir" ]; then
  echo
  echo "Note: $varOutDir/ exists. Prior output files may be overwritten."
  read -p "Press Enter to continue..."
else
  mkdir "$varOutDir"
fi

if [ "$varInMode" != "Results" ]; then fnScan; fi
fnParse

echo
echo "=======================================[ fin ]======================================="
echo
