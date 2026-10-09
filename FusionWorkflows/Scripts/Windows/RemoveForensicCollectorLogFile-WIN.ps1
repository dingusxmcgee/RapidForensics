# check for existing log files and delete them if they exist
# we look for them in sys32 because that's where Crowdstrike drops them, if your env is different you may need to change this.
$files = get-childitem "C:\windows\system32\Collector_velociraptor*.log*"
if ($files) {
  $files | foreach {
    Remove-Item $_.FullName -Force
  }
}