$ErrorActionPreference = 'Stop'

# 首个 TDD 测试：发布检查器尚未实现时必须明确失败。
$repository_path = Split-Path -Parent $PSScriptRoot
$checker_path = Join-Path $repository_path 'scripts\check_release.ps1'

if (-not (Test-Path -LiteralPath $checker_path -PathType Leaf)) {
    throw "尚未找到发布检查器：$checker_path"
}

$fixture_path = Join-Path $env:TEMP ("content-asset-release-fixture-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $fixture_path | Out-Null
Set-Content -LiteralPath (Join-Path $fixture_path 'release_allowlist.txt') -Value "README.md`nrelease_allowlist.txt" -NoNewline
Set-Content -LiteralPath (Join-Path $fixture_path 'README.md') -Value '# 模板' -NoNewline
git -C $fixture_path init -q
git -C $fixture_path add README.md release_allowlist.txt
& $checker_path -RepositoryPath $fixture_path
if ($LASTEXITCODE -ne 0) { throw '合规夹具应通过发布检查' }

Set-Content -LiteralPath (Join-Path $fixture_path 'private-note.md') -Value '不应发布' -NoNewline
git -C $fixture_path add private-note.md
$was_rejected = $false
try {
    & $checker_path -RepositoryPath $fixture_path 2>$null
    if ($LASTEXITCODE -ne 0) { $was_rejected = $true }
} catch {
    $was_rejected = $true
}
if (-not $was_rejected) { throw '未白名单文件必须被拒绝' }

$empty_fixture = Join-Path $env:TEMP ("content-asset-empty-fixture-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $empty_fixture | Out-Null
Set-Content -LiteralPath (Join-Path $empty_fixture 'release_allowlist.txt') -Value '# 仅注释' -NoNewline
git -C $empty_fixture init -q
git -C $empty_fixture add release_allowlist.txt
$was_rejected = $false
try { & $checker_path -RepositoryPath $empty_fixture 2>$null; if ($LASTEXITCODE -ne 0) { $was_rejected = $true } } catch { $was_rejected = $true }
if (-not $was_rejected) { throw '空白名单必须被拒绝' }

$obsidian_fixture = Join-Path $env:TEMP ("content-asset-obsidian-fixture-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path (Join-Path $obsidian_fixture '.obsidian') | Out-Null
Set-Content -LiteralPath (Join-Path $obsidian_fixture 'release_allowlist.txt') -Value ".obsidian/app.json`nrelease_allowlist.txt" -NoNewline
Set-Content -LiteralPath (Join-Path $obsidian_fixture '.obsidian\app.json') -Value '{}' -NoNewline
git -C $obsidian_fixture init -q
git -C $obsidian_fixture add .
$was_rejected = $false
try { & $checker_path -RepositoryPath $obsidian_fixture 2>$null; if ($LASTEXITCODE -ne 0) { $was_rejected = $true } } catch { $was_rejected = $true }
if (-not $was_rejected) { throw '.obsidian 路径必须被拒绝' }

$binary_fixture = Join-Path $env:TEMP ("content-asset-binary-fixture-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $binary_fixture | Out-Null
Set-Content -LiteralPath (Join-Path $binary_fixture 'release_allowlist.txt') -Value "sample.md`nrelease_allowlist.txt" -NoNewline
[IO.File]::WriteAllBytes((Join-Path $binary_fixture 'sample.md'), [byte[]](35, 0, 65))
git -C $binary_fixture init -q
git -C $binary_fixture add .
$was_rejected = $false
try { & $checker_path -RepositoryPath $binary_fixture 2>$null; if ($LASTEXITCODE -ne 0) { $was_rejected = $true } } catch { $was_rejected = $true }
if (-not $was_rejected) { throw '含 NUL 字节的文件必须被拒绝' }

$symlink_fixture = Join-Path $env:TEMP ("content-asset-symlink-fixture-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $symlink_fixture | Out-Null
Set-Content -LiteralPath (Join-Path $symlink_fixture 'release_allowlist.txt') -Value "link.md`nrelease_allowlist.txt" -NoNewline
git -C $symlink_fixture init -q
git -C $symlink_fixture add release_allowlist.txt
$link_blob = 'target.md' | git -C $symlink_fixture hash-object -w --stdin
git -C $symlink_fixture update-index --add --cacheinfo "120000,$link_blob,link.md"
$was_rejected = $false
try { & $checker_path -RepositoryPath $symlink_fixture 2>$null; if ($LASTEXITCODE -ne 0) { $was_rejected = $true } } catch { $was_rejected = $true }
if (-not $was_rejected) { throw '软链接必须被拒绝' }

$demo_fixture = Join-Path $env:TEMP ("content-asset-demo-fixture-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $demo_fixture | Out-Null
Set-Content -LiteralPath (Join-Path $demo_fixture 'release_allowlist.txt') -Value "演示-样例.md`nrelease_allowlist.txt" -NoNewline
Set-Content -LiteralPath (Join-Path $demo_fixture '演示-样例.md') -Value '# 缺少标记' -NoNewline
git -C $demo_fixture init -q
git -C $demo_fixture add .
$was_rejected = $false
try { & $checker_path -RepositoryPath $demo_fixture 2>$null; if ($LASTEXITCODE -ne 0) { $was_rejected = $true } } catch { $was_rejected = $true }
if (-not $was_rejected) { throw '缺少虚构演示标记必须被拒绝' }

$nested_demo_fixture = Join-Path $env:TEMP ("content-asset-nested-demo-fixture-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path (Join-Path $nested_demo_fixture 'docs') | Out-Null
Set-Content -LiteralPath (Join-Path $nested_demo_fixture 'release_allowlist.txt') -Value "docs/演示-样例.md`nrelease_allowlist.txt" -NoNewline
Set-Content -LiteralPath (Join-Path $nested_demo_fixture 'docs\演示-样例.md') -Value '# 缺少标记' -NoNewline
git -C $nested_demo_fixture init -q
git -C $nested_demo_fixture add .
$was_rejected = $false
try { & $checker_path -RepositoryPath $nested_demo_fixture 2>$null; if ($LASTEXITCODE -ne 0) { $was_rejected = $true } } catch { $was_rejected = $true }
if (-not $was_rejected) { throw '嵌套演示文件缺少标记必须被拒绝' }
