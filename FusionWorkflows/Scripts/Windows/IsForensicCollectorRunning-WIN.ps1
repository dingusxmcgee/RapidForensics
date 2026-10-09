$for_process_name = "RapidForensics-Collector*"

#normalize text
$fpn = $for_process_name.ToLower()

#get matches
$formatches = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Name.ToLower() -like $fpn })



#output as pscustomobject for fusion workflow
$out = [pscustomobject]@{
  for_process_name = $for_process_name
  for_is_running   = ($formatches.Count -gt 0)
  for_count        = [int]$formatches.Count
  for_pids         = @($formatches | ForEach-Object { [int]$_.Id } | Sort-Object -Unique)
}

#convert to json
$out | ConvertTo-Json -Compress