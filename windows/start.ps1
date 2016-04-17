clear
$VM= "default"
$DOCKER_MACHINE="./docker-machine.exe"
$DOCKER_MACHINE_CMD="docker-machine.exe"
$useVbox = false;
$useHyperv = false;
$machineAbsent = false;

if (Test-Path $DOCKER_MACHINE) {
  Write-Host("Docker Machine is not installed. Please re-run the Toolbox Installer and try again.");
  exit 1
}

$VM_EXISTS = (docker-machine.exe ls --filter Name="default")[1].indexOf("default") -gt -1;

if ($VM_EXISTS -eq $false) {
  Write-Host("Docker Machine status: Machine not present");
  $machineAbsent = $true;
}

$hypervInstalled = (Get-Command get-vm).ModuleName.toUpper() -eq "HYPER-V";
Write-Host("hypervInstalled: $hypervInstalled");
if ($hypervInstalled -eq $false) {
  $VBOX_MSI_INSTALL_PATH = get-childitem -path env:VBOX_MSI_INSTALL_PATH;
  $VBOX_INSTALL_PATH = get-childitem -path env:VBOX_INSTALL_PATH;
  if ($VBOX_INSTALL_PATH -eq "" -And $VBOX_INSTALL_PATH -eq "") {
    Write-Host("No hyper-v present, will try to find virtualbox");
    exit 1;
  } else {
    $useVbox = $true;
  }
} else {
  Write-Host("Hyper-v present, will not try to find virtualbox");
  $useHyperv = $true;
}

if ($machineAbsent -eq $true) {
  Write-Host("Try to create machine");
  if ($useHyperv -eq $true) {
    $switchName = (Get-VMSwitch | Select Name)[0].Name;
    Write-Host("Found switch: '$switchName'");
    $cmd = "$DOCKER_MACHINE_CMD -D create --driver hyperv --hyperv-memory 2048 --hyperv-virtual-switch '$switchName' $VM";
    iex $cmd;
  } elseif ($useVbox -eq $true) {
    $cmd = "$DOCKER_MACHINE_CMD -D create --driver virtualbox --virtualbox-memory 2048 $VM";
    iex $cmd;
  }
}

$VM_STATUS = ((docker-machine.exe ls --filter Name="default") -match "running").length -eq 1;
if ($VM_STATUS -ne $true) {
    Write-Host("Docker Machine status: Not Running");
} else {
    Write-Host("Docker Machine status: Running");
}

& "docker-machine.exe" env $VM | Invoke-Expression

Write-Host("docker is configured to use the ${VM} machine with IP ${DOCKER_MACHINE} ip ${VM}");

& sh -c "$*" | Invoke-Expression