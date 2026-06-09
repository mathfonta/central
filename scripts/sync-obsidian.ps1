# sync-obsidian.ps1
# Copia os Status.md do Obsidian para o repo central e faz push automatico.
# Executar manualmente ou via Agendador de Tarefas (instalar-tarefa.ps1).

$ErrorActionPreference = 'Stop'

# ── Configuracao ──────────────────────────────────────
$obsidianAutoPostDir = "G:\Meu Drive\OBSidian\AutoPost"
$obsidianObrasDir    = "G:\Meu Drive\OBSidian\Obras"
$centralRepo         = "C:\Projetos\central"

# Busca qualquer arquivo cujo nome contenha "Status" e termine em .md
function Find-StatusMd($dir) {
    if (-not (Test-Path $dir)) { return $null }
    $file = Get-ChildItem -Path $dir -Filter "*Status*.md" -Recurse -Depth 2 -ErrorAction SilentlyContinue | Select-Object -First 1
    return $file
}

# ── Verificacoes iniciais ──────────────────────────────
if (-not (Test-Path $centralRepo)) {
    Write-Host "ERRO: Repo nao encontrado em $centralRepo" -ForegroundColor Red
    exit 1
}

# ── Git pull ANTES de copiar arquivos ─────────────────
Set-Location $centralRepo
Write-Host "Sincronizando com GitHub..." -ForegroundColor Cyan

# Descarta qualquer versao local dos arquivos gerados (serao recriados abaixo)
git checkout -- status-autopost.md status-obras.md 2>&1 | Out-Null

$pullResult = git pull --rebase 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Aviso git pull: $pullResult" -ForegroundColor Yellow
} else {
    Write-Host $pullResult
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
    $errors += "AutoPost: nenhum *Status*.md em $obsidianAutoPostDir"
    Write-Host "AVISO: $($errors[-1])" -ForegroundColor Yellow
}

# ── Copiar Obras ───────────────────────────────────────
$obrasFile = Find-StatusMd $obsidianObrasDir
if ($obrasFile) {
    Copy-Item $obrasFile.FullName "$centralRepo\status-obras.md" -Force
    $synced += "Obras"
    Write-Host "OK Obras: $($obrasFile.Name)" -ForegroundColor Green
} else {
    $errors += "Obras: nenhum *Status*.md em $obsidianObrasDir"
    Write-Host "AVISO: $($errors[-1])" -ForegroundColor Yellow
}

# ── Nada para sync ─────────────────────────────────────
if ($synced.Count -eq 0) {
    Write-Host "Nenhum arquivo encontrado. Verifique se o Google Drive esta montado." -ForegroundColor Red
    exit 1
}

# ── Commitar e push ────────────────────────────────────
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
