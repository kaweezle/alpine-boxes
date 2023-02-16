function RunDockerInWsl {
  # Take $Env:DOCKER_WSL or 'docker' if undefined
  $DockerWSL = if ($null -eq $Env:DOCKER_WSL) { "docker" } else { $Env:DOCKER_WSL }
  # Try to find an existing distribution with the name
  $existing = Get-ChildItem HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss |  Where-Object { $_.GetValue('DistributionName') -eq $DockerWSL }
  if ($null -eq $existing) {
    # Fail if the distribution doesn't exist
    throw "The WSL distribution [$DockerWSL] does not exist !"
  } else {
    # Ensure docker is started
    wsl -d $DockerWSL -u root openrc default
    # Perform the requested command
    wsl -d $DockerWSL /usr/bin/docker $args
  }
}

Set-Alias -Name docker -Value RunDockerInWsl
