<#
.SYNOPSIS
  Scan a list of IPs and Hostnames and report ping results and downtime.
  
.DESCRIPTION
  Uses PowerShell Workflow and one ping to accompish tasks in parrallel. 
  
.PARAMETER <Parameter_Name>
   Modify included ServerList.txt with IPs and Hostnames desired for monitoring.
	
.INPUTS
  None
  
.OUTPUTS
  Text to Powershell Console, CSV files of monitored hosts and _Downtime.csv
  
.NOTES
  Version:        	3.03
  Author:         	Dennis Ozmert
  GitHub:	  	https://github.com/VoidNet-ops
  Creation Date: 	20/10/2021 @ 9:00am
  Last Updated:   	18/11/2021
  Purpose/Change:	Network hardware cutover
  License:		GNU General Public License
  
.EXAMPLE
  .\pingMonitoring.ps1
 
.CITED WORK
  LordZillion, https://www.reddit.com/r/PowerShell/comments/2lragu/is_there_any_way_to_run_testconnection_on_every/
  shelladmin, https://shellgeek.com/powershell-using-test-connection-to-ping-list-of-computers/  
#>
# --------------------------------------------------
## Imports and values
#
# Paths, inputs and outputs
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition #Find path of running script
$inputFile = "$scriptPath\ServerList.txt" #.txt file of IP/hostname inputs
[System.Array]$serverList = Get-Content $inputFile
$windowTitle = "pingMonitoring_$IP" #Unused, will incorperate later
# --------------------------------------------------
##Code start
#
$host.ui.RawUI.WindowTitle = $windowTitle
workflow TestConnectionsSweep
{
    param(
        [System.String[]]$Servers
    )
    $pingLoop1 = 0 #Leave starting as 0
    $pingLoop2 = ([int32]::MaxValue) #Currently set as endless
    While ($pingLoop1 -le $pingLoop2)
    {
        Foreach -Parallel ($s in $Servers)
        {
            $outFile = "$s.csv" #Filename for success results
            $outFile2 = "_Downtime.csv" #Filename for failed results
            $outPath = "C:\Users\user0\Desktop\pingMonitoring" #"$scriptPath\pingMonitoring" #!!!BROKEN, update Test-Connection output path manually
            $pingCount = 1
            $pingDelay = 1
            $upTrue = $true
            $upCheck = Test-Connection -ComputerName $s -Count $pingCount -Delay $pingDelay -Quiet -ErrorAction SilentlyContinue #Needed to verify host availability before if-else
            if ($upCheck)
            {
                #write-output($s + " is online.")
                $pingResults = Test-Connection -ComputerName $s -Count $pingCount -Delay $pingDelay -ErrorAction SilentlyContinue
                $pingResults2 = $pingResults #Duplicates output for writing.
                write-output $pingResults  #Writes output to screen
                $pingResults2 | Select @{n='TimeStamp';e={Get-Date}}, @{n='PingSource';e={$_.PSComputerName}}, Address, ReplySize, ResponseTime | Export-Csv "$outPath\$outFile" -Append -NoTypeInformation #Writes to .csv
            }
            else
            {
                $pingReuslts3 = ($($(Get-Date -Format G) + " : ")+($s+" : ")+("unreachable"))
                write-output $pingReuslts3
                $sTimestamp = ($(Get-Date -Format G))
                $sPingSource = ([System.Net.Dns]::GetHostName())
                $sAddress = ($s)
                $sReplySize = ("N/A")
                $sResponseTime = ("unreachable")
                $pingResults4 = [pscustomobject][ordered]@{
                    "Timestamp" = $sTimestamp
                    'PingSource' = $sPingSource
                    'Address'  = $sAddress
                    'ReplySize' = $sReplySize
                    'ResponseTime' = $sResponseTime
                    }
                $pingResults4 | Export-Csv "$outPath\$outFile" -Append -NoTypeInformation #Writes to host CSV
                $pingResults4 | Export-Csv "$outPath\$outFile2" -Append -NoTypeInformation #Writes to failure CSV
            }
        }

    }
}
TestConnectionsSweep -Servers $serverList
# --------------------------------------------------
