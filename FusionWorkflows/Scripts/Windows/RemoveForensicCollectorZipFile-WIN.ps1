###Deletes forensic collection zip file based on user choice

#get neweset collector zip file
# we look for them in sys32 because that's where Crowdstrike drops them, if your env is different you may need to change this.
$zipfound = $false
try {
  $zipfile = get-childitem "C:\windows\system32\Collection-*.zip" -ErrorAction Stop | sort-object LastWritetime -Descending | Select-Object -First 1
  $fullname = $zipfile.FullName
  $zipfound = $true
}

catch {
  $filenotfound = $_
  $zipfound = $false
}
#try to delete zip file
if ($zipfound) {
  $zipremoved = $false
  try {
    Remove-Item $fullname -Force -ErrorAction stop
    $zipremoved = $true
  }
  catch {
    $removeerror = $_
    $zipremoved = $false
  }
}
#output results
$out = [pscustomobject]@{
zip_found = $zipfound
zip_removed   = $zipremoved
file_not_found_error = $filenotfound
file_not_removed_error   = $removeerror
}

$out | ConvertTo-Json -Compress