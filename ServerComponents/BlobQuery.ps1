#Set default mode to user so download process is interactive. scheduled task will call script with 'auto' mode to auto download newest collections.
param($mode="user") 


##############################################
# This script is for automated or manual downloading 
# of new forensic collections from an azure storage blob.
#
# The parameter will ensure that the script is run in manual mode when you run with powershell or right click and choose 'run with powershell'
# If you desire to run this in an automatic fashion, via service or sch task etc, just run the script with 'auto' supplied as a parameter.
#
##############################################


#Azure storage blob variables
$accountName="ACCOUNT_NAME"
$accountKey="ACCOUNT_KEY"
$accountContainer = "ACCOUNT_CONTAINER"

#Other important variables
$global:FolderPath = "D:\RapidForensics"
$global:casepath = "$FolderPath\Cases"
$global:tobeanalyzedpath = "$FolderPath\ToBeAnalyzed"
$global:archivepath = "$FolderPath\AnalyzedArchive" 


#LogData Function
Function LogData($loglevel, $function, $data)
    {
        #Log Data to screen and log file
        # log in UTC timestamp
        $timestamp = [DateTime]::UtcNow.ToString('u')

        if ($function -eq 'triage')
            {
                $data = "TRIAGE - " + $data
            }

        if ($function -eq 'blobquery')
            {
                $data = "BLOBQUERY - " + $data
            }
        
        if ($loglevel -eq 'info')
            {
                Write-Output "$timestamp - $data"
                Write-Output "$timestamp - $data" | Out-File $logFile -Append
            }
        if ($loglevel -eq 'error')
            {
                Write-Output "$timestamp - !!ERROR!!: $data"
                Write-Output "$timestamp - !!ERROR!!: $data" | Out-File $logFile -Append
            }
        
    }

#Function to auto download newest collections.
Function AutoDownload 
    {

        #check log file for recency so that we only make one log file per day
        $files = get-childitem -path "$FolderPath\Logs"
        $newestlog = $files | sort-object CreationTime -Descending | select -first 1
        $newestlogdate = ([datetime]$newestlog.CreationTimeUtc).date
        $currentdate = ([datetime]$(get-date -format M-d-yyyy)).date

        #if current log is same day, use it
        if ($currentdate -eq $newestlogdate)
            {
                $logFile = "$FolderPath\Logs\$newestlog"
                LogData info blobquery "Using exsiting log file"
            }

        #if current date is later than newest log file, create a new one.
        if ($currentdate -gt $newestlogdate)
            {
                #make a new log file
                $logDateTime = [DateTime]::UtcNow.ToString('u').replace(' ','__').replace(':','-')
                $logFile = "$FolderPath\Logs\RapidForensicsTriageLog_$logDateTime.txt"
                New-Item -Type file -Path $logFile | Out-Null
                LogData info blobquery "Logfile created at $logFile" $logFile
            }


        LogData info blobquery "Starting in automatic mode...."


        #get az storage container context
        LogData info blobquery "Getting Azure Storage Context..."
                                                                                                                                                                                                                                                                                                                                                                        try {
        $ctx = New-AzStorageContext -ConnectionString "DefaultEndpointsProtocol=https;AccountName=$accountName;AccountKey=$accountKey;" -ErrorAction Stop
        Logdata info blobquery "Acquired storage context for blob $($ctx.StorageAccountName)"
        Logdata info blobquery "Getting list of files in blob..."

        #get files in blob
        try {
                $blobfiles = Get-AzStorageBlob -Container $accountContainer -Context $ctx -ErrorAction Stop
                Logdata info blobquery "Found $($blobfiles.count) files in blob"
                Logdata info blobquery "Getting newest file..."

                #get the newest file
                try 
                    {
                        $newestfile = $blobfiles | sort-object LastModified -descending | select -first 1
                        Logdata info blobquery "Found newest file $($newestfile.Name)"
                        Logdata info blobquery "Downloading newest file for analysis"

                        #download file
                        try
                            {
                                $filename = $newestfile.Name
                                $downloadedfile = Get-AzStorageBlobContent -container $accountContainer -context $ctx -blob $newestfile.Name -destination $tobeanalyzedpath\$filename -ErrorAction Stop
                                $filesize = (get-childitem $tobeanalyzedpath\$filename).Length/1024/1024/1024
                                $filesize = [math]::Round($filesize,2)
                                Logdata info blobquery "File downloaded to $tobeanalyzedpath\$filename : Approx Size: $filesize GB "
                                Logdata info blobquery "All done!"
                                Logdata info blobquery "---------------------------------------"
                                Exit
                            }
                        catch
                            {
                                Logdata error blobquery  "Error downloading newest file: $($_.Exception.Message)"
                                Exit
                            }
                    }
                catch
                    {
                        Logdata error blobquery  "Error accessing newest file: $($_.Exception.Message)"
                        Exit
                    }
            }
        catch
            {
                Logdata error blobquery "Error accessing blob to get contents: $($_.Exception.Message)"
                Exit
            }
    }
        catch
            {
                Logdata error blobquery "Error acquiring storage context: $($_.Exception.Message)"
                exit
            }
    }

#Function for user interactive downloading of collections.
Function UserDownload
    {
        #check log file for recency so that we only make one log file per day
        $files = get-childitem -path "$FolderPath\Logs"
        $newestlog = $files | sort-object CreationTime -Descending | select -first 1
        $newestlogdate = ([datetime]$newestlog.CreationTimeUtc).date
        $currentdate = ([datetime]$(get-date -format M-d-yyyy)).date

        #if current log is same day, use it
        if ($currentdate -eq $newestlogdate)
            {
                $logFile = "$FolderPath\Logs\$newestlog"
                LogData info blobquery "Using exsiting log file"
            }

        #if current date is later than newest log file, create a new one.
        if ($currentdate -gt $newestlogdate)
            {
                #make a new log file
                $logDateTime = [DateTime]::UtcNow.ToString('u').replace(' ','__').replace(':','-')
                $logFile = "$FolderPath\Logs\RapidForensicsTriageLog_$logDateTime.txt"
                New-Item -Type file -Path $logFile | Out-Null
                LogData info blobquery "Logfile created at $logFile" $logFile
            }


        LogData info blobquery "Starting in user interactive mode...."


        #get az storage container context
        LogData info blobquery "Getting Azure Storage Context..."
                                                                                                                                                                                                                                                                                                                                                                        try {
        $ctx = New-AzStorageContext -ConnectionString "DefaultEndpointsProtocol=https;AccountName=$accountName;AccountKey=$accountKey;" -ErrorAction Stop
        Logdata info blobquery "Acquired storage context for blob $($ctx.StorageAccountName)"
        Logdata info blobquery "Getting list of files in blob..."

        #get files in blob and output to user
        try {
                $blobfiles = Get-AzStorageBlob -Container $accountContainer -Context $ctx -ErrorAction Stop | Sort-Object LastModified -Descending
                Logdata info blobquery "Found $($blobfiles.count) files in blob"
                
                $bloboutput = [PSCustomObject]@{}
                $Index = 0
                $bloboutput = foreach ($file in $blobfiles) 
                    {
                        $Name = $file.Name
                        $Size = "$([math]::round($file.length/1024/1024,2))" + "mb"
                        $LastModified = $file.LastModified

                        [PSCustomObject]@{
                        Index = $Index
                        Name = $Name
                        Size = $Size
                        LastModified = $LastModified
                        }

                        #iterate Index value
                        $Index += 1
                    }
                    Write-Output "-----------------"
                    Write-Output "BLOB FILES FOUND"
                    Write-Output "-----------------"
                    $bloboutput | format-table

                #get the user selected file
                try 
                    {
                        $userchoice = Read-Host "Using the table above select a collection to download based on its Index #"

                        #validate user choice
                        $array = $bloboutput | foreach {$_.Index}
                        while ($array -notcontains $userchoice)
                            {
                                #logdata
                                Write-Output "User choice of $($userchoice) was not found in list, ensure selection was correct and try again"
                                $userchoice = Read-Host "Using the table above select a collection to download based on its Index #"
                            }
                        $filetodownload = $bloboutput[$userchoice].Name
                       
                        Logdata info blobquery "User selected collection for download: $($filetodownload)"
                        Logdata info blobquery "Downloading collection for analysis"

                        #download file
                        try
                            {
                                $filename = $filetodownload
                                $downloadedfile = Get-AzStorageBlobContent -container $accountContainer -context $ctx -blob $filetodownload -destination $tobeanalyzedpath\$filename -ErrorAction Stop
                                $filesize = (get-childitem $tobeanalyzedpath\$filename).Length/1024/1024/1024
                                $filesize = [math]::Round($filesize,2)
                                Logdata info blobquery "File downloaded to $tobeanalyzedpath\$filename : Approx Size: $filesize GB "
                                Logdata info blobquery "All done!"
                                Logdata info blobquery "---------------------------------------"
                                Read-Host "Press enter to exit"
                                Exit
                            }
                        catch
                            {
                                Logdata error blobquery  "Error downloading selected file: $($_.Exception.Message)"
                                Exit
                            }
                    }
                catch
                    {
                        Logdata error blobquery  "Error accessing selected file: $($_.Exception.Message)"
                        Exit
                    }
            }
        catch
            {
                Logdata error blobquery "Error accessing blob to get contents: $($_.Exception.Message)"
                Exit
            }
    }
        catch
            {
                Logdata error blobquery "Error acquiring storage context: $($_.Exception.Message)"
                exit
            }

    }


if ($mode -eq "user")
    {
        UserDownload
    }
if ($mode -eq "auto")
    {
        AutoDownload
    }

read-host "pause"