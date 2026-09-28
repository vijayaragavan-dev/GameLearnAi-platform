# GameLearn AI - audio asset synthesizer.
# Generates all SFX + music loop WAVs (16-bit PCM, mono, 22050 Hz).
# All sounds are original synthesized tones - royalty free by construction.

param([string]$OutDir = "assets\audio")

$ErrorActionPreference = "Stop"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$rate = 22050

function Write-Wav {
    param(
        [string]$Path,
        [float[]]$Samples
    )
    $ms = New-Object System.IO.MemoryStream
    $bw = New-Object System.IO.BinaryWriter($ms)

    $dataLen = $Samples.Length * 2
    # RIFF header
    $bw.Write([Text.Encoding]::ASCII.GetBytes("RIFF"))
    $bw.Write([UInt32](36 + $dataLen))
    $bw.Write([Text.Encoding]::ASCII.GetBytes("WAVE"))
    $bw.Write([Text.Encoding]::ASCII.GetBytes("fmt "))
    $bw.Write([UInt32]16)
    $bw.Write([UInt16]1)          # PCM
    $bw.Write([UInt16]1)          # mono
    $bw.Write([UInt32]$rate)
    $bw.Write([UInt32]($rate * 2))# byte rate
    $bw.Write([UInt16]2)          # block align
    $bw.Write([UInt16]16)         # bits per sample
    $bw.Write([Text.Encoding]::ASCII.GetBytes("data"))
    $bw.Write([UInt32]$dataLen)

    foreach ($s in $Samples) {
        $v = [Math]::Max(-1.0, [Math]::Min(1.0, $s))
        $bw.Write([Int16][Math]::Round($v * 32000))
    }
    $bw.Flush()
    [IO.File]::WriteAllBytes((Join-Path (Get-Location) $Path), $ms.ToArray())
    $bw.Close(); $ms.Close()
}

function Env-AD {
    param([int]$Len, [double]$AttackFrac = 0.05, [double]$Curve = 3.0)
    # Attack-decay envelope array of length $len.
    $env = New-Object "float[]" $Len
    $attack = [Math]::Max(1, [int]($Len * $AttackFrac))
    for ($i = 0; $i -lt $Len; $i++) {
        if ($i -lt $attack) {
            $env[$i] = $i / $attack
        } else {
            $t = ($i - $attack) / ($Len - $attack)
            $env[$i] = [Math]::Pow(1.0 - $t, $Curve)
        }
    }
    return ,$env
}

function Tone {
    param([double]$Freq, [double]$Seconds, [double]$Amp = 0.6, [double]$Decay = 3.0)
    $len = [int]($Seconds * $rate)
    $e = Env-AD -Len $len -Curve $Decay
    $out = New-Object "float[]" $len
    for ($i = 0; $i -lt $len; $i++) {
        $t = $i / $rate
        $out[$i] = $Amp * $e[$i] * [Math]::Sin(2 * [Math]::PI * $Freq * $t)
    }
    return ,$out
}

function Mix {
    param([object[]]$Tracks)
    # Each track = @{ Samples=float[]; DelayMs=int }
    $total = 0
    foreach ($tr in $Tracks) {
        $end = [int]($tr.DelayMs * $rate / 1000) + $tr.Samples.Length
        if ($end -gt $total) { $total = $end }
    }
    $mix = New-Object "float[]" $total
    foreach ($tr in $Tracks) {
        $off = [int]($tr.DelayMs * $rate / 1000)
        for ($i = 0; $i -lt $tr.Samples.Length; $i++) {
            $mix[$off + $i] += $tr.Samples[$i]
        }
    }
    return ,$mix
}

function SoftClip {
    param([float[]]$S)
    for ($i = 0; $i -lt $S.Length; $i++) {
        $x = $S[$i]
        # tanh-ish soft clip keeps peaks musical.
        if ($x -gt 0.9 -or $x -lt -0.9) { $x = [Math]::Tanh($x) }
        $S[$i] = $x * 0.85
    }
    return ,$S
}

# ---- SFX ------------------------------------------------------------------

# Tap: tiny soft tick
Write-Wav -Path "$OutDir\sfx_tap.wav" -Samples (Tone -Freq 850 -Seconds 0.06 -Amp 0.32 -Decay 7)

# Confirm: two-tone rise
Write-Wav -Path "$OutDir\sfx_confirm.wav" -Samples (SoftClip (Mix @(
    @{ Samples = (Tone -Freq 620 -Seconds 0.09 -Amp 0.42); DelayMs = 0 },
    @{ Samples = (Tone -Freq 930 -Seconds 0.12 -Amp 0.42); DelayMs = 70 }
)))

# Correct: major arpeggio C5-E5-G5
Write-Wav -Path "$OutDir\sfx_correct.wav" -Samples (SoftClip (Mix @(
    @{ Samples = (Tone -Freq 523.25 -Seconds 0.22 -Amp 0.4); DelayMs = 0 },
    @{ Samples = (Tone -Freq 659.25 -Seconds 0.22 -Amp 0.4); DelayMs = 80 },
    @{ Samples = (Tone -Freq 783.99 -Seconds 0.3 -Amp 0.45); DelayMs = 160 }
)))

# Incorrect: descending minor pair
Write-Wav -Path "$OutDir\sfx_incorrect.wav" -Samples (SoftClip (Mix @(
    @{ Samples = (Tone -Freq 392 -Seconds 0.18 -Amp 0.4 -Decay 2); DelayMs = 0 },
    @{ Samples = (Tone -Freq 293.66 -Seconds 0.26 -Amp 0.4 -Decay 2); DelayMs = 110 }
)))

# XP gain: rising sweep
$len = [int](0.35 * $rate); $xp = New-Object "float[]" $len
$eXp = Env-AD -Len $len -Curve 2
for ($i = 0; $i -lt $len; $i++) {
    $t = $i / $rate
    $f = 480 + 900 * ($t / 0.35)
    $phase = 2 * [Math]::PI * (480 * $t + 450 * ($t * $t) / 0.35)
    $xp[$i] = 0.5 * $eXp[$i] * [Math]::Sin($phase)
}
Write-Wav -Path "$OutDir\sfx_xp.wav" -Samples (SoftClip $xp)

# Level up: triumphant stack
Write-Wav -Path "$OutDir\sfx_levelup.wav" -Samples (SoftClip (Mix @(
    @{ Samples = (Tone -Freq 392 -Seconds 0.5 -Amp 0.34 -Decay 1.4); DelayMs = 0 },
    @{ Samples = (Tone -Freq 493.88 -Seconds 0.5 -Amp 0.34 -Decay 1.4); DelayMs = 60 },
    @{ Samples = (Tone -Freq 587.33 -Seconds 0.55 -Amp 0.36 -Decay 1.4); DelayMs = 120 },
    @{ Samples = (Tone -Freq 783.99 -Seconds 0.7 -Amp 0.44 -Decay 1.6); DelayMs = 240 }
)))

# Achievement: shimmer arpeggio
Write-Wav -Path "$OutDir\sfx_achievement.wav" -Samples (SoftClip (Mix @(
    @{ Samples = (Tone -Freq 659.25 -Seconds 0.25 -Amp 0.38); DelayMs = 0 },
    @{ Samples = (Tone -Freq 987.77 -Seconds 0.25 -Amp 0.36); DelayMs = 90 },
    @{ Samples = (Tone -Freq 1318.51 -Seconds 0.35 -Amp 0.4); DelayMs = 180 }
)))

# Mission complete: solid chord
Write-Wav -Path "$OutDir\sfx_mission.wav" -Samples (SoftClip (Mix @(
    @{ Samples = (Tone -Freq 523.25 -Seconds 0.4 -Amp 0.36 -Decay 1.6); DelayMs = 0 },
    @{ Samples = (Tone -Freq 659.25 -Seconds 0.4 -Amp 0.34 -Decay 1.6); DelayMs = 20 },
    @{ Samples = (Tone -Freq 1046.5 -Seconds 0.45 -Amp 0.3 -Decay 1.8); DelayMs = 40 }
)))

# Node unlock: pop with pitch bend down
$nlen = [int](0.14 * $rate); $pop = New-Object "float[]" $nlen
$ePop = Env-AD -Len $nlen -Curve 4
for ($i = 0; $i -lt $nlen; $i++) {
    $t = $i / $rate
    $f = 1150 - 420 * ($t / 0.14)
    $pop[$i] = 0.5 * $ePop[$i] * [Math]::Sin(2 * [Math]::PI * $f * $t)
}
Write-Wav -Path "$OutDir\sfx_node.wav" -Samples (SoftClip $pop)

# Streak: warm double pulse
Write-Wav -Path "$OutDir\sfx_streak.wav" -Samples (SoftClip (Mix @(
    @{ Samples = (Tone -Freq 330 -Seconds 0.2 -Amp 0.4 -Decay 2.2); DelayMs = 0 },
    @{ Samples = (Tone -Freq 440 -Seconds 0.26 -Amp 0.42 -Decay 2); DelayMs = 130 }
)))

# Notification: gentle ding
Write-Wav -Path "$OutDir\sfx_notification.wav" -Samples (Tone -Freq 880 -Seconds 0.4 -Amp 0.34 -Decay 3.5)

# ---- Music loops -----------------------------------------------------------
# Seamless: every partial completes an integer number of cycles over T.

function PadLoop {
    param([double]$Seconds, [object[]]$Partials)
    $len = [int]($Seconds * $rate)
    $out = New-Object "float[]" $len
    foreach ($p in $Partials) {
        $cycles = [Math]::Round($p.Freq * $Seconds)   # force integer cycles
        for ($i = 0; $i -lt $len; $i++) {
            $t = $i / $rate
            $out[$i] += $p.Amp * [Math]::Sin(2 * [Math]::PI * $cycles * $t / $Seconds + $p.Phase)
        }
    }
    # Normalize gently.
    $peak = 0.0001
    foreach ($v in $out) { $a = [Math]::Abs($v); if ($a -gt $peak) { $peak = $a } }
    for ($i = 0; $i -lt $len; $i++) { $out[$i] = $out[$i] / $peak * 0.5 }
    return ,$out
}

# Menu: warm Am pad (A2 C3 E3 + A3) - 6 seconds
Write-Wav -Path "$OutDir\music_menu.wav" -Samples (PadLoop -Seconds 6 -Partials @(
    @{ Freq = 110.0;  Amp = 0.5; Phase = 0.0 },
    @{ Freq = 130.81; Amp = 0.4; Phase = 1.1 },
    @{ Freq = 164.81; Amp = 0.4; Phase = 2.2 },
    @{ Freq = 220.0;  Amp = 0.25; Phase = 0.6 },
    @{ Freq = 329.63; Amp = 0.14; Phase = 2.9 }
))

# Adventure: Dm-Bb-ish drifting pad - 8 seconds
Write-Wav -Path "$OutDir\music_adventure.wav" -Samples (PadLoop -Seconds 8 -Partials @(
    @{ Freq = 146.83; Amp = 0.5; Phase = 0.3 },
    @{ Freq = 174.61; Amp = 0.38; Phase = 1.7 },
    @{ Freq = 220.0;  Amp = 0.34; Phase = 2.6 },
    @{ Freq = 233.08; Amp = 0.2; Phase = 0.9 },
    @{ Freq = 349.23; Amp = 0.12; Phase = 2.0 }
))

# Quiz: focused minor pad with slight pulse - 6 seconds
Write-Wav -Path "$OutDir\music_quiz.wav" -Samples (PadLoop -Seconds 6 -Partials @(
    @{ Freq = 123.47; Amp = 0.48; Phase = 0.2 },
    @{ Freq = 146.83; Amp = 0.4; Phase = 1.4 },
    @{ Freq = 196.0;  Amp = 0.3; Phase = 2.4 },
    @{ Freq = 293.66; Amp = 0.16; Phase = 0.8 }
))

Write-Output "Audio assets written to ${OutDir}:"
Get-ChildItem $OutDir | ForEach-Object { "{0}  ({1:N1} KB)" -f $_.Name, ($_.Length / 1KB) }
