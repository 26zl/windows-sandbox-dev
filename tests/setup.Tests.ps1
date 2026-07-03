# Pester tests for setup.ps1: profile resolution, dedup, and sandbox.wsb generation.
BeforeAll {
    $repoRoot = Split-Path $PSScriptRoot -Parent

    # Copy the inputs setup.ps1 needs into an isolated dir so tests never touch the repo.
    function Copy-LabFixture {
        param([string]$Base)
        $dir = Join-Path $Base ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path (Join-Path $dir 'scripts') -Force | Out-Null
        Copy-Item (Join-Path $repoRoot 'setup.ps1') $dir
        Copy-Item (Join-Path $repoRoot 'tools.json') $dir
        Copy-Item (Join-Path $repoRoot 'sandbox.wsb.template') $dir
        return $dir
    }

    # Run in a child process because setup.ps1 uses `exit`.
    function Invoke-Setup {
        param([string]$Dir, [string[]]$Arguments = @())
        & pwsh -NoProfile -File (Join-Path $Dir 'setup.ps1') @Arguments *> $null
        return $LASTEXITCODE
    }
}

Describe 'setup.ps1' {
    It 'generates scripts/tools.json and sandbox.wsb with defaults' {
        $dir = Copy-LabFixture -Base $TestDrive
        Invoke-Setup -Dir $dir | Should -Be 0

        $tools = (Get-Content -Raw (Join-Path $dir 'scripts/tools.json') | ConvertFrom-Json).tools
        $tools.Count | Should -BeGreaterThan 0

        $wsb = Get-Content -Raw (Join-Path $dir 'sandbox.wsb')
        $wsb | Should -Not -Match '__'  # every template placeholder replaced
        $wsb | Should -Match '<Networking>Enable</Networking>'
        $wsb | Should -Match '<ClipboardRedirection>Enable</ClipboardRedirection>'
    }

    It 'dedupes tools shared across profiles' {
        $dir = Copy-LabFixture -Base $TestDrive
        Invoke-Setup -Dir $dir -Arguments @('-Profiles', 'security,pentest') | Should -Be 0

        # Wireshark is listed in both the security and pentest profiles.
        $tools = (Get-Content -Raw (Join-Path $dir 'scripts/tools.json') | ConvertFrom-Json).tools
        @($tools | Where-Object wingetId -eq 'WiresharkFoundation.Wireshark').Count | Should -Be 1
    }

    It 'rejects unknown profile names' {
        $dir = Copy-LabFixture -Base $TestDrive
        Invoke-Setup -Dir $dir -Arguments @('-Profiles', 'nope') | Should -Be 1
    }

    It 'disables networking and clipboard in offline mode' {
        $dir = Copy-LabFixture -Base $TestDrive
        Invoke-Setup -Dir $dir -Arguments @('-Offline') | Should -Be 0

        $wsb = Get-Content -Raw (Join-Path $dir 'sandbox.wsb')
        $wsb | Should -Match '<Networking>Disable</Networking>'
        $wsb | Should -Match '<ClipboardRedirection>Disable</ClipboardRedirection>'
        $wsb | Should -Match 'launch\.cmd -Offline'
    }
}
