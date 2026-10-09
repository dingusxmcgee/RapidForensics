###IsForensicCollectorCompleted - WIN
###Checks log file to see if collector is completed and uploaded to azure

#get neweset collector log file
$logfile = get-childitem "C:\windows\system32\Collector_velociraptor*" | sort-object LastWritetime -Descending | Select-Object -First 1
$fullname = $logfile.FullName
#read content
$read = Get-Content $fullname
#check if completed
$completed = $read | Select-String -Pattern "Collection completed"

# if collector complete, check for azure timestamps and set success
if ($completed) {
  #get matches for azure upload function
  $matches = $read | Select-String -Pattern "upload_azure"
  # get count of matches minus one to find last entry in 0 index
  $count = $matches.count -1
  # get start and end time of azure upload based on first and last azure log entry and calculate total time
  $azure_start_time = Get-Date ($matches[0] | ConvertFrom-Json).time
  $azure_end_time = Get-Date ($matches[$count] | ConvertFrom-Json).time
  $azure_upload_time = ([math]::Round($(($azure_end_time - $azure_start_time).TotalMinutes),2)).ToString() + " Minutes"

  $completed_time = ($completed[0] | ConvertFrom-Json).time
  $completed_total = ($completed[0] | ConvertFrom-Json).msg

  $out = [pscustomobject]@{
  azure_start_time = $azure_start_time
  azure_end_time   = $azure_end_time
  azure_upload_time = $azure_upload_time
  completed_time   = $completed_time
  completed_total = $completed_total
  collection_complete = $true
  logfile_path = $fullname
}

$out | ConvertTo-Json -Compress

}
# if collector not complete, set incomplete
else {
    $out = [pscustomobject]@{
  collection_complete = $false
}

$out | ConvertTo-Json -Compress

}