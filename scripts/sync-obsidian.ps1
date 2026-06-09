# sync-obsidian.ps1
# Copia os Status.md do Obsidian para o repo central e faz push automatico.
# Executar manualmente ou via Agendador de Tarefas (instalar-tarefa.ps1).

$ErrorActionPreference = 'Stop'

# ── Configuracao ──────────────────────────────────────
$obsidianAutoPostDir = "G:\Meu Drive\OBSidian\AutoPost"
$obsidianObrasDir    = "G:\Meu Drive\OBSidian\Obras"
$centralRepo         = "C:\Projetos\central"

# Usa wildcard para evitar problema de encoding com emoji no nome do arquivo
function Find-StatusMd($dir) {
    if (-not (Test-Path $dir)) { return $null }
    $file = Get-ChildItem -Path $dir -Filter "*Status.md" -ErrorAction SilentlyContinue | Select-Object -First 1
    return $file
}

# ── Verificacoes iniciais ──────────────────────────────
if (-not (Test-Path $centralRepo)) {
    Write-Host "ERRO: Repo nao encontrado em $centralRepo" -ForegroundColor Red
    Write-Host "Clone o repo: git clone https://github.com/mathfonta/central.git $centralRepo"
    exit 1
}

$synced = @()
$errors = @()

# ── Copiar AutoPost ────────────────────────────────────
$autoPostFile = Find-StatusMd $obsidianAutoPostDir
if ($autoPostFile) {
    Copy-Item $autoPostFile.FullName "$centralRepo\status-autopost.md" -Force
    $synced += "AutoPost"
    Write-Host "OK AutoPost: $($autoPostFile.Name)" -ForegroundColor Green
} else {
    $errors += "AutoPost: nenhum *Status.md em $obsidianAutoPostDir"
    Write-Host "AVISO: $($errors[-1])" -ForegroundColor Yellow
}

# ── Copiar Obras ───────────────────────────────────────
$obrasFile = Find-StatusMd $obsidianObrasDir
if ($obrasFile) {
    Copy-Item $obrasFile.FullName "$centralRepo\status-obras.md" -Force
    $synced += "Obras"
    Write-Host "OK Obras: $($obrasFile.Name)" -ForegroundColor Green
} else {
    $errors += "Obras: nenhum *Status.md em $obsidianObrasDir"
    Write-Host "AVISO: $($errors[-1])" -ForegroundColor Yellow
}

# ── Nada para sync ─────────────────────────────────────
if ($synced.Count -eq 0) {
    Write-Host "Nenhum arquivo encontrado. Verifique se o Google Drive esta montado." -ForegroundColor Red
    exit 1
}

# ── Git push ───────────────────────────────────────────
Set-Location $centralRepo

$changed = git status --porcelain status-autopost.md status-obras.md
if (-not $changed) {
    Write-Host "Sem mudancas para commitar." -ForegroundColor Cyan
    exit 0
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
git add status-autopost.md status-obras.md
git commit -m "chore: sync obsidian status [$timestamp]"
git push

Write-Host ""
Write-Host "Sync concluido: $($synced -join ', ')" -ForegroundColor Green
if ($errors.Count -gt 0) {
    Write-Host "Avisos: $($errors -join '; ')" -ForegroundColor Yellow
}
