BeforeAll {
    $script:MathToolPath = Join-Path $PSScriptRoot 'math-tool.ps1'
    . $script:MathToolPath -N 0
}

Describe 'Get-Fibonacci' {
    It 'returns 0 for N=0' {
        $result = Get-Fibonacci -N 0
        $result | Should -Be 0
        $result | Should -BeOfType [System.Numerics.BigInteger]
    }

    It 'returns 1 for N=1' {
        $result = Get-Fibonacci -N 1
        $result | Should -Be 1
        $result | Should -BeOfType [System.Numerics.BigInteger]
    }

    It 'returns 8 for N=6 (representative value)' {
        $result = Get-Fibonacci -N 6
        $result | Should -Be 8
        $result | Should -BeOfType [System.Numerics.BigInteger]
    }

    It 'throws for a negative N' {
        { Get-Fibonacci -N -1 } | Should -Throw
    }
}

Describe 'math-tool.ps1 direct CLI execution' {
    BeforeAll {
        function Invoke-MathToolCli {
            param(
                [Parameter(Mandatory = $true)]
                [int]$N
            )

            $output = & pwsh -NoLogo -NoProfile -File $script:MathToolPath -N $N
            [PSCustomObject]@{
                Output   = $output
                ExitCode = $LASTEXITCODE
            }
        }
    }

    It 'writes exactly one line "Fibonacci(0) = 0" and exits successfully' {
        $result = Invoke-MathToolCli -N 0
        @($result.Output).Count | Should -Be 1
        $result.Output | Should -Be 'Fibonacci(0) = 0'
        $result.ExitCode | Should -Be 0
    }

    It 'writes exactly one line "Fibonacci(1) = 1" and exits successfully' {
        $result = Invoke-MathToolCli -N 1
        @($result.Output).Count | Should -Be 1
        $result.Output | Should -Be 'Fibonacci(1) = 1'
        $result.ExitCode | Should -Be 0
    }

    It 'writes exactly one line "Fibonacci(6) = 8" and exits successfully' {
        $result = Invoke-MathToolCli -N 6
        @($result.Output).Count | Should -Be 1
        $result.Output | Should -Be 'Fibonacci(6) = 8'
        $result.ExitCode | Should -Be 0
    }
}
