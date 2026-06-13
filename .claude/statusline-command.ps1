$input_data = $input | Out-String | ConvertFrom-Json

# [char]27 (ESC) invece di `e: `e funziona solo in PowerShell 7+, questo va anche su Windows PowerShell 5.1
$E = [char]27
$RESET  = "$E[0m"
$BOLD   = "$E[1m"
$RED    = "$E[38;5;196m"
$ORANGE = "$E[38;5;214m"
$YELLOW = "$E[38;5;226m"
$GREEN  = "$E[38;5;82m"
$CYAN   = "$E[38;5;51m"
$BLUE   = "$E[38;5;39m"
$PURPLE = "$E[38;5;135m"
$PINK   = "$E[38;5;213m"
$WHITE  = "$E[38;5;255m"
$GRAY   = "$E[38;5;240m"

$SEP   = " $GRAY|$RESET "
$parts = [System.Collections.Generic.List[string]]::new()

# Rate limit 5-hour (first)
$five_hr = $input_data.rate_limits.five_hour.used_percentage
if ($null -ne $five_hr) {
    $five_int = [math]::Round($five_hr)
    $rl_color = if ($five_int -ge 80) { $RED } elseif ($five_int -ge 50) { $ORANGE } else { $GREEN }
    $parts.Add("${rl_color}5h:$five_int%$RESET")
}

# Model
$model = $input_data.model.display_name
if (-not $model) { $model = $input_data.model.id }
if ($model) { $parts.Add("${BLUE}$model$RESET") }

# Context usage bar
$used_pct = $input_data.context_window.used_percentage
if ($null -ne $used_pct) {
    $used_int   = [math]::Round($used_pct)
    $bar_filled = [math]::Round($used_int / 10)
    $bar_empty  = 10 - $bar_filled
    $bar        = ("#" * $bar_filled) + ("-" * $bar_empty)
    $bar_color  = if ($used_int -ge 80) { $RED } elseif ($used_int -ge 50) { $ORANGE } else { $GREEN }
    $parts.Add("${bar_color}ctx[$bar]$used_int%$RESET")
}

# Session name
$session = $input_data.session_name
if ($session) { $parts.Add("${PURPLE}${BOLD}[$session]$RESET") }

# Directory (shortened if > 35 chars)
$cwd = $input_data.workspace.current_dir
if (-not $cwd) { $cwd = $input_data.cwd }
$home_dir = $env:USERPROFILE -replace '\\', '/'
$norm_cwd = ($cwd -replace '\\', '/') -replace [regex]::Escape($home_dir), '~'

$max_path_len = 35
if ($norm_cwd.Length -gt $max_path_len) {
    $clean = @($norm_cwd -split '/' | Where-Object { $_.Length -gt 0 })
    if ($clean.Count -ge 4) {
        $short_cwd = "$($clean[0])/.../$($clean[-2])/$($clean[-1])"
    } elseif ($clean.Count -eq 3) {
        $short_cwd = "$($clean[0])/.../$($clean[-1])"
    } else {
        $short_cwd = $norm_cwd
    }
} else {
    $short_cwd = $norm_cwd
}

$parts.Add("${CYAN}${BOLD}$short_cwd$RESET")

# Git repo / worktree
$repo = $input_data.workspace.repo
if ($repo -and $repo.owner) {
    $repo_str = "$($repo.owner)/$($repo.name)"
    $wt = $input_data.workspace.git_worktree
    if ($wt) { $repo_str = "$repo_str`:$wt" }
    $parts.Add("${YELLOW}($repo_str)$RESET")
}

# PR badge
$pr = $input_data.pr
if ($pr -and $pr.number) {
    $pr_color = switch ($pr.review_state) {
        "approved"          { $GREEN }
        "changes_requested" { $RED }
        "draft"             { $GRAY }
        default             { $ORANGE }
    }
    $parts.Add("${pr_color}PR#$($pr.number)$RESET")
}

# Effort level
$effort = $input_data.effort.level
if ($effort) {
    $eff_color = switch ($effort) {
        "low"    { $GRAY }
        "medium" { $GREEN }
        "high"   { $ORANGE }
        "xhigh"  { $RED }
        "max"    { $PINK }
        default  { $WHITE }
    }
    $parts.Add("${eff_color}effort:$effort$RESET")
}

# Token usage
$total_in  = $input_data.context_window.total_input_tokens
$total_out = $input_data.context_window.total_output_tokens
if ($null -ne $total_in -or $null -ne $total_out) {
    $fmt = { param($n) if ($n -ge 1000) { "{0:0.0}k" -f ($n / 1000) } else { "$n" } }
    # Assegnazione separata: (if ...) come argomento non è valido in Windows PowerShell 5.1
    $in_val  = if ($null -ne $total_in)  { $total_in }  else { 0 }
    $out_val = if ($null -ne $total_out) { $total_out } else { 0 }
    $in_fmt  = & $fmt $in_val
    $out_fmt = & $fmt $out_val
    $parts.Add("${GRAY}tok in:${WHITE}$in_fmt${GRAY} out:${WHITE}$out_fmt$RESET")
}

# Vim mode
$vim_mode = $input_data.vim.mode
if ($vim_mode) {
    $vm_color = switch -Wildcard ($vim_mode) {
        "INSERT"  { $GREEN }
        "NORMAL"  { $CYAN }
        "VISUAL*" { $ORANGE }
        default   { $WHITE }
    }
    $parts.Add("${vm_color}${BOLD}[$vim_mode]$RESET")
}

Write-Host ($parts -join $SEP)
