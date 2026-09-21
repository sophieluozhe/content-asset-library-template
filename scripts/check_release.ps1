param(
    [Parameter(Mandatory = $true)]
    [string]$RepositoryPath
)

$ErrorActionPreference = 'Stop'
$root_path = [IO.Path]::GetFullPath($RepositoryPath)
$allowlist_path = Join-Path $root_path 'release_allowlist.txt'

if (-not (Test-Path -LiteralPath $allowlist_path -PathType Leaf)) {
    Write-Error '缺少 release_allowlist.txt'
    exit 1
}

$allowlist = Get-Content -LiteralPath $allowlist_path | ForEach-Object { $_.Trim() } |
    Where-Object { $_ -and -not $_.StartsWith('#') }

if (@($allowlist).Count -eq 0) {
    Write-Error '白名单没有有效条目'
    exit 1
}

$staged_paths = @(git -c core.quotepath=false -C $root_path diff --cached --name-only)
if ($LASTEXITCODE -ne 0) {
    Write-Error '无法读取 Git 暂存区'
    exit 1
}

$index_entries = @(git -c core.quotepath=false -C $root_path ls-files -s)
foreach ($entry in $index_entries) {
    if ($entry -match '^(120000|160000)\s+\S+\s+\d+\t(.+)$') {
        Write-Error "不允许的 Git 对象：$($Matches[2])"
        exit 1
    }
}

$errors = @($staged_paths | Where-Object {
    $_ -and (($_ -notin $allowlist) -or $_ -match '(^|/)\.obsidian(/|$)')
})
if ($errors.Count -gt 0) {
    $errors | ForEach-Object { Write-Error "未在白名单中：$_" }
    exit 1
}

foreach ($path in $staged_paths) {
    if (-not $path) { continue }
    $process_info = [Diagnostics.ProcessStartInfo]::new()
    $process_info.FileName = 'git'
    $process_info.UseShellExecute = $false
    $process_info.RedirectStandardOutput = $true
    $process_info.ArgumentList.Add('-C')
    $process_info.ArgumentList.Add($root_path)
    $process_info.ArgumentList.Add('show')
    $process_info.ArgumentList.Add(":$path")
    $process = [Diagnostics.Process]::Start($process_info)
    $buffer = [IO.MemoryStream]::new()
    $process.StandardOutput.BaseStream.CopyTo($buffer)
    $process.WaitForExit()
    if ($process.ExitCode -ne 0) { Write-Error "无法读取暂存文件：$path"; exit 1 }
    $blob_bytes = $buffer.ToArray()
    if ($blob_bytes -contains [byte]0) { Write-Error "含 NUL 字节：$path"; exit 1 }
    if ([IO.Path]::GetFileName($path) -like '演示-*.md' -and -not ([Text.Encoding]::UTF8.GetString($blob_bytes).Contains('虚构演示'))) {
        Write-Error "缺少虚构演示标记：$path"
        exit 1
    }
}

exit 0
