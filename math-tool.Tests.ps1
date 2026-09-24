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

Describe 'Get-Factorial' {
    It 'returns 1 for N=0' {
        $result = Get-Factorial -N 0
        $result | Should -Be 1
        $result | Should -BeOfType [System.Numerics.BigInteger]
    }

    It 'returns 1 for N=1' {
        $result = Get-Factorial -N 1
        $result | Should -Be 1
        $result | Should -BeOfType [System.Numerics.BigInteger]
    }

    It 'returns 120 for N=5 (representative value)' {
        $result = Get-Factorial -N 5
        $result | Should -Be 120
        $result | Should -BeOfType [System.Numerics.BigInteger]
    }

    It 'throws for a negative N' {
        { Get-Factorial -N -1 } | Should -Throw
    }
}

Describe 'math-tool.ps1 direct CLI execution' {
    BeforeAll {
        function Invoke-MathToolCli {
            param(
                [Parameter(Mandatory = $true)]
                [int]$N,

                [Parameter(Mandatory = $false)]
                [string]$Operation
            )

            if ($PSBoundParameters.ContainsKey('Operation')) {
                $output = & pwsh -NoLogo -NoProfile -File $script:MathToolPath -N $N -Operation $Operation
            }
            else {
                $output = & pwsh -NoLogo -NoProfile -File $script:MathToolPath -N $N
            }

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

    It 'writes exactly one line "Factorial(0) = 1" and exits successfully' {
        $result = Invoke-MathToolCli -N 0 -Operation 'factorial'
        @($result.Output).Count | Should -Be 1
        $result.Output | Should -Be 'Factorial(0) = 1'
        $result.ExitCode | Should -Be 0
    }

    It 'writes exactly one line "Factorial(1) = 1" and exits successfully' {
        $result = Invoke-MathToolCli -N 1 -Operation 'factorial'
        @($result.Output).Count | Should -Be 1
        $result.Output | Should -Be 'Factorial(1) = 1'
        $result.ExitCode | Should -Be 0
    }

    It 'writes exactly one line "Factorial(5) = 120" and exits successfully' {
        $result = Invoke-MathToolCli -N 5 -Operation 'factorial'
        @($result.Output).Count | Should -Be 1
        $result.Output | Should -Be 'Factorial(5) = 120'
        $result.ExitCode | Should -Be 0
    }

    It 'dispatches on the requested operation for the same N' {
        $fibonacci = Invoke-MathToolCli -N 5 -Operation 'fibonacci'
        $factorial = Invoke-MathToolCli -N 5 -Operation 'factorial'

        @($fibonacci.Output).Count | Should -Be 1
        $fibonacci.Output | Should -Be 'Fibonacci(5) = 5'
        $fibonacci.ExitCode | Should -Be 0

        @($factorial.Output).Count | Should -Be 1
        $factorial.Output | Should -Be 'Factorial(5) = 120'
        $factorial.ExitCode | Should -Be 0
    }
}
