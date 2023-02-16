function RunPodmanInWsl {
  # Take $Env:PODMAN_WSL or 'docker' if undefined
  $PodmanWSL = if ($null -eq $Env:PODMAN_WSL) { "podman" } else { $Env:PODMAN_WSL }
  # Try to find an existing distribution with the name
  $existing = Get-ChildItem HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss |  Where-Object { $_.GetValue('DistributionName') -eq $PodmanWSL }
  if ($null -eq $existing) {
    # Fail if the distribution doesn't exist
    throw "The WSL distribution [$PodmanWSL] does not exist !"
  } else {
    # Perform the requested command
    wsl -d $PodmanWSL -u alpine /usr/bin/podman $args
  }
}

Set-Alias -Name docker -Value RunPodmanInWsl
