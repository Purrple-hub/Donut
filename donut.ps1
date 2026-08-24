<#
.SYNOPSIS
    Spinning 3D donut rendered in the terminal with a decorative box frame.
.DESCRIPTION
    This script renders a rotating 3D donut using ASCII characters. The donut is
    enclosed in a box frame for a polished, retro-terminal aesthetic.
    Press Ctrl+C to exit.
#>

# Hide the cursor and clear the screen
Write-Host -NoNewline "`e[?25l"
Write-Host -NoNewline "`e[2J"

# ANSI color codes
$RESET = "`e[0m"
$CYAN = "`e[36m"
$YELLOW = "`e[33m"
$GREEN = "`e[32m"
$MAGENTA = "`e[35m"

# Donut parameters
$A = 0.0
$B = 0.0

# Render loop control
$script:stop = $false

# Render the donut with a box frame
function Render-Donut {
    param(
        [double]$A,
        [double]$B
    )
    
    # Get terminal size
    $w = $Host.UI.RawUI.WindowSize.Width
    $h = $Host.UI.RawUI.WindowSize.Height
    
    # Ensure minimum size
    if ($w -lt 50) { $w = 50 }
    if ($h -lt 25) { $h = 25 }
    
    # Donut geometry parameters (tuned for a clean look)
    $R1 = 0.6
    $R2 = 1.8
    $K2 = 5.0
    $K1 = $w * $K2 * 3 / (8 * ($R1 + $R2))
    
    # Precompute trig for current rotation
    $sinA = [Math]::Sin($A)
    $cosA = [Math]::Cos($A)
    $sinB = [Math]::Sin($B)
    $cosB = [Math]::Cos($B)
    
    # Buffers
    $buf = New-Object char[] ($w * $h)
    $zbuf = New-Object double[] ($w * $h)
    
    # Initialize buffers
    for ($i = 0; $i -lt $buf.Length; $i++) {
        $buf[$i] = ' '
        $zbuf[$i] = 0.0
    }
    
    # Torus sampling
    $theta_step = 0.04
    $phi_step = 0.02
    
    $theta = 0.0
    while ($theta -lt 2 * [Math]::PI) {
        $ct = [Math]::Cos($theta)
        $st = [Math]::Sin($theta)
        
        $circlex = $R2 + $R1 * $ct
        $circley = $R1 * $st
        
        $phi = 0.0
        while ($phi -lt 2 * [Math]::PI) {
            $cp = [Math]::Cos($phi)
            $sp = [Math]::Sin($phi)
            
            # 3D torus coordinates with full rotation
            $x = $circlex * ($cosB * $cp + $sinA * $sinB * $sp) - $circley * $cosA * $sinB
            $y = $circlex * ($sinB * $cp - $sinA * $cosB * $sp) + $circley * $cosA * $cosB
            $z = $K2 + $cosA * $circlex * $sp + $circley * $sinA
            
            $ooz = 1.0 / $z
            $xp = [int]($w/2 + $K1 * $ooz * $x)
            $yp = [int]($h/2 - $K1 * $ooz * $y)
            
            # Luminance
            $L = ($cp * $ct * $sinB - $cosA * $ct * $sp - $sinA * $st + $cosB * ($cosA * $st - $ct * $sinA * $sp))
            
            if ($L -gt 0 -and $xp -ge 0 -and $xp -lt $w -and $yp -ge 0 -and $yp -lt $h) {
                $idx = $xp + $yp * $w
                if ($ooz -gt $zbuf[$idx]) {
                    $zbuf[$idx] = $ooz
                    $lum = [Math]::Min([int]($L * 14), 11)
                    $buf[$idx] = " .,-~:;=!*#$@"[$lum]
                }
            }
            
            $phi += $phi_step
        }
        $theta += $theta_step
    }
    
    # Build the frame with the donut inside
    $frame = New-Object System.Text.StringBuilder
    
    # Top border
    $frame.Append("$CYAN+") | Out-Null
    $frame.Append('-' * ($w - 2)) | Out-Null
    $frame.AppendLine("+$RESET") | Out-Null
    
    # Rows with side borders
    for ($y = 0; $y -lt $h; $y++) {
        $frame.Append("$CYAN|$RESET") | Out-Null
        $rowStart = $y * $w
        $rowEnd = $rowStart + $w
        for ($x = 0; $x -lt $w; $x++) {
            $idx = $rowStart + $x
            $ch = $buf[$idx]
            # Apply a subtle gradient color to the donut
            if ($ch -ne ' ') {
                # Alternate colors based on position for a glow effect
                $color = if (($x + $y) % 3 -eq 0) { $YELLOW } elseif (($x + $y) % 3 -eq 1) { $GREEN } else { $MAGENTA }
                $frame.Append("$color$ch$RESET") | Out-Null
            } else {
                $frame.Append(' ') | Out-Null
            }
        }
        $frame.AppendLine("$CYAN|$RESET") | Out-Null
    }
    
    # Bottom border
    $frame.Append("$CYAN+") | Out-Null
    $frame.Append('-' * ($w - 2)) | Out-Null
    $frame.AppendLine("+$RESET") | Out-Null
    
    # Move cursor home and render
    Write-Host -NoNewline "`e[H"
    Write-Host -NoNewline $frame.ToString()
}

# Main loop
function Start-Donut {
    try {
        while (-not $script:stop) {
            Render-Donut -A $A -B $B
            $script:A += 0.06
            $script:B += 0.03
            Start-Sleep -Milliseconds 30
        }
    }
    finally {
        # Cleanup: show cursor and clear screen
        Write-Host -NoNewline "`e[H`e[J`e[?25h"
    }
}

# Handle Ctrl+C gracefully
$ctrlCHandler = {
    $script:stop = $true
    Write-Host -NoNewline "`e[H`e[J`e[?25h"
    [Environment]::Exit(0)
}
[Console]::TreatControlCAsInput = $false
[Console]::CancelKeyPress += $ctrlCHandler

# Start the animation
Start-Donut
