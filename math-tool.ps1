[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(0, [int]::MaxValue)]
    [int]$N,

    [Parameter(Mandatory = $false)]
    [ValidateSet('fibonacci', 'factorial')]
    [string]$Operation = 'fibonacci'
)

function Get-Fibonacci {
    [CmdletBinding()]
    [OutputType([System.Numerics.BigInteger])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$N
    )

    [System.Numerics.BigInteger]$previous = 0
    [System.Numerics.BigInteger]$current = 1
    for ($i = 0; $i -lt $N; $i++) {
        $next = $previous + $current
        $previous = $current
        $current = $next
    }
    return $previous
}

function Get-Factorial {
    [CmdletBinding()]
    [OutputType([System.Numerics.BigInteger])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$N
    )

    [System.Numerics.BigInteger]$product = 1
    for ($i = 2; $i -le $N; $i++) {
        $product = $product * $i
    }
    return $product
}

if ($MyInvocation.InvocationName -ne '.') {
    switch ($Operation) {
        'factorial' {
            $value = Get-Factorial -N $N
            Write-Output "Factorial($N) = $value"
        }
        default {
            $value = Get-Fibonacci -N $N
            Write-Output "Fibonacci($N) = $value"
        }
    }
}
