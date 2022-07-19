<powershell>
function Random-Password($length, $minNonAlpha) {
  $alpha = [char]65..[char]90 + [char]97..[char]122
  $numeric  =  [char]48..[char]57
  # :;<=>?@!#$%&()*+,-./[\]^_`
  $symbols = [char]58..[char]64 + @([char]33) + [char]35..[char]38 + [char]40..[char]47 + [char]91..[char]96

  $nonAlpha = $numeric + $symbols
  $charSet = $alpha + $nonAlpha

  $pwdList = @()
  For ($i = 0; $i -lt $minNonAlpha; $i++) {
    $pwdList += $nonAlpha | Get-Random
  }
  For ($i = 0; $i -lt ($length - $minNonAlpha); $i++) {
    $pwdList += $charSet | Get-Random
  }

  $pwdList = $pwdList | Sort-Object { Get-Random }

  # a bug on Server 2016 joins as stringified integers unles we cast to [char[]]
  ([char[]] $pwdList) -join ""
}

# UE 5.0 on windows only spawns 1 thread per physical core, doing this we can configure it to spawn 1 thread per logical core
$processor = Get-ComputerInfo -Property CsProcessors
$processorCountMultiplier = $processor.CsProcessors.NumberOfLogicalProcessors / $processor.CsProcessors.NumberOfCores
$maxParallelActions = $processor.CsProcessors.NumberOfLogicalProcessors

echo @"
<?xml version="1.0" ?>
<Configuration xmlns="https://www.unrealengine.com/BuildConfiguration">
  <BuildConfiguration>
          <MaxParallelActions>$maxParallelActions</MaxParallelActions>
  </BuildConfiguration>
  <ParallelExecutor>
          <MaxProcessorCount>$maxParallelActions</MaxProcessorCount>
          <ProcessorCountMultiplier>$processorCountMultiplier</ProcessorCountMultiplier>
  </ParallelExecutor>
</Configuration>
"@ > "C:\Users\Administrator\AppData\Roaming\Unreal Engine\UnrealBuildTool\BuildConfiguration.xml"


# We install the CircleCI agent, this is mostly taken from https://github.com/CircleCI-Public/runner-installation-files/blob/main/windows-install/Install-CircleCIRunner.ps1

$platform = "windows/amd64"
$installDirPath = "$env:ProgramFiles\CircleCI"

# Install Chocolatey
Write-Host "Installing Chocolatey as a prerequisite"
Invoke-Expression ((Invoke-WebRequest "https://chocolatey.org/install.ps1").Content)
Write-Host ""

# Install Git
Write-Host "Installing Git, which is required to run CircleCI jobs"
choco install -y git --params "/GitAndUnixToolsOnPath"
Write-Host ""

# Install Gzip
Write-Host "Installing Gzip, which is required to run CircleCI jobs"
choco install -y gzip
Write-Host ""

Write-Host "Installing CircleCI Launch Agent to $installDirPath"

# mkdir
[void](New-Item "$installDirPath" -ItemType Directory -Force)
Push-Location "$installDirPath"

# Download launch-agent
$agentDist = "https://circleci-binary-releases.s3.amazonaws.com/circleci-launch-agent"
Write-Host "Determining latest version of CircleCI Launch Agent"
$agentVer = (Invoke-WebRequest "$agentDist/release.txt").Content.Trim()
Write-Host "Using CircleCI Launch Agent version $agentVer"
Write-Host "Downloading and verifying CircleCI Launch Agent Binary"
$agentChecksum = ((Invoke-WebRequest "$agentDist/$agentVer/checksums.txt").Content.Split("`n") | Select-String $platform).Line.Split(" ")
$agentHash = $agentChecksum[0]
$agentFile = $agentChecksum[1].Split("/")[-1]
Write-Host "Downloading CircleCI Launch Agent: $agentFile"
Invoke-WebRequest "$agentDist/$agentVer/$platform/$agentFile" -OutFile "$agentFile"
Write-Host "Verifying CircleCI Launch Agent download"
if ((Get-FileHash "$agentFile" -Algorithm SHA256).Hash.ToLower() -ne $agentHash.ToLower()) {
    throw "Invalid checksum for CircleCI Launch Agent, please try download again"
}

# NT credentials to use
Write-Host "Generating a random password"
$username = "circleci"
$passwd = Random-Password 42 10
$passwdSecure = $(ConvertTo-SecureString -String $passwd -AsPlainText -Force)
$cred = New-Object System.Management.Automation.PSCredential ($username, $passwdSecure)

# Create a user with the generated password
Write-Host "Creating a new administrator user to run CircleCI tasks"
$user = New-LocalUser $username -Password $passwdSecure -PasswordNeverExpires

# Make the user an administrator
Add-LocalGroupMember Administrators $user

# Save the credential to Credential Manager for sans-prompt MSTSC
# First for the current user, and later for the runner user
Write-Host "Saving the password to Credential Manager"
Start-Process cmdkey.exe -ArgumentList ("/add:TERMSRV/localhost", "/user:$username", "/pass:$passwd")
Start-Process cmdkey.exe -ArgumentList ("/add:TERMSRV/localhost", "/user:$username", "/pass:$passwd") -Credential $cred

Write-Host "Configuring Remote Desktop Client"

[void](reg.exe ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation" "/v" "AllowSavedCredentialsWhenNTLMOnly" /t REG_DWORD /d 0x1 /f)
[void](reg.exe ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation" "/v" "ConcatenateDefaults_AllowSavedNTLMOnly" /t REG_DWORD /d 0x1 /f)
[void](reg.exe ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowSavedCredentialsWhenNTLMOnly" /v "1" /t REG_SZ /d "TERMSRV/localhost" /f)
gpupdate.exe /force

# Configure MSTSC to suppress interactive prompts on RDP connection to localhost
Start-Process reg.exe -ArgumentList ("ADD", '"HKCU\Software\Microsoft\Terminal Server Client"', "/v", "AuthenticationLevelOverride", "/t", "REG_DWORD", "/d", "0x0", "/f") -Credential $cred

# Stop starting Server Manager at logon
Start-Process reg.exe -ArgumentList ("ADD", '"HKCU\Software\Microsoft\ServerManager"', "/v", "DoNotOpenServerManagerAtLogon", "/t", "REG_DWORD", "/d", "0x1", "/f") -Credential $cred

# Configure scheduled tasks to run launch-agent
Write-Host "Registering CircleCI Launch Agent tasks to Task Scheduler"
$commonTaskSettings = New-ScheduledTaskSettingsSet -Compatibility Vista -AllowStartIfOnBatteries -ExecutionTimeLimit (New-TimeSpan)
[void](Register-ScheduledTask -Force -TaskName "CircleCI Launch Agent" -User $username -Action (New-ScheduledTaskAction -Execute powershell.exe -Argument "-Command `"& `"`"$installDirPath\$agentFile`"`"`"`" --config `"`"$installDirPath\launch-agent-config.yaml`"`"`"; & logoff.exe (Get-Process -Id `$PID).SessionID`"") -Settings $commonTaskSettings -Trigger (New-ScheduledTaskTrigger -AtLogon -User $username) -RunLevel Highest)
$keeperTask = Register-ScheduledTask -Force -TaskName "CircleCI Launch Agent session keeper" -User $username -Password $passwd -Action (New-ScheduledTaskAction -Execute powershell.exe -Argument "-Command `"while (`$true) { if ((query session $username).Length -eq 0) { mstsc.exe /v:localhost; Start-Sleep 5 } Start-Sleep 1 }`"") -Settings $commonTaskSettings -Trigger (New-ScheduledTaskTrigger -AtStartup)


# Get the EC2 Instance ID from the Metadata API to use as runner name.
$instanceId = (Invoke-WebRequest -Uri http://169.254.169.254/latest/meta-data/instance-id -UseBasicParsing).Content

# Preparing config template
Write-Host "Preparing a config template for CircleCI Launch Agent"
@"
api:
  auth_token: "${auth_token}"
runner:
  name: "$instanceId"
  mode: continuous
  working_directory: C:\Users\Administrator\AppData\Local\Temp\%s
  cleanup_working_directory: true
logging:
  file: $installDirPath\circleci-runner.log
"@ -replace "([^`r])`n", "`$1`r`n" | Out-File launch-agent-config.yaml -Encoding ascii


# We create a powershell script to mount the FSx share when our pipelines run.
echo @"
`$Drive = "Z"
`$AD_SHARE = '\\${fsx_dns_name}\fsx\'

# Check if the drive is there or not.
`$MappedDrive = (Get-PSDrive -Name `$Drive -ErrorAction SilentlyContinue)

if (!(`$MappedDrive)) {
    Write-Output "[Info] Trying to mount `$AD_SHARE as `$Drive"
    New-PSDrive -Name `$Drive -Scope Global -Root `$AD_SHARE -Persist -PSProvider "FileSystem"
}
"@ > C:\mount_fsx.ps1

# Start runner!
Write-Host "Starting CircleCI Launch Agent"
Pop-Location
Start-ScheduledTask -InputObject $keeperTask
Write-Host ""

</powershell>
<persist>true</persist>