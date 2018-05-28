param(
    [Switch]$Release
)

Import-Module (Join-Path $PSScriptRoot "PSDocker") -Force
$ModulePath = "$PSScriptRoot\..\..\output"
$Init = [ScriptBlock]::Create("Import-Module Docker -Force")

Describe "Ubuntu" {
    Context "dashboard running" {
        Get-DockerContainer -All -Name "TestContainer" | Remove-DockerContainer -Force
        New-DockerContainer -Name "TestContainer" -Repository "microsoft/powershell" -Tag "ubuntu-16.04" -Port 10001
        Start-DockerContainer -Name "TestContainer"
        Invoke-DockerCommand -ContainerName "TestContainer" -ScriptBlock {
            New-Item UniversalDashboard -ItemType directory | Out-Null
        }
        Copy-DockerItem -ToContainer "TestContainer" -Source $ModulePath -Destination "/UniversalDashboard"
        
        Start-Job {
            Invoke-DockerCommand -ContainerName "TestContainer" -ScriptBlock {
                Import-Module '/UniversalDashboard/output/UniversalDashboard.psd1'
                Enable-UDLogging
                Start-UDDashboard -Port 10001 -Dashboard (New-UDDashboard -Title 'Hey' -Content {}) -Wait
            } 
        } -Init $Init
        
        Start-Sleep 4

        It "should be running dashboard" {
            Invoke-RestMethod http://localhost:10001/dashboard | Should not be $null
        }

        Get-DockerContainer -All -Name "TestContainer" | Remove-DockerContainer -Force
        Get-Job | Remove-Job -Force
    }
}
