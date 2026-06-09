# sync-obsidian.ps1
# Copia os Status.md do Obsidian para o repo central e faz push automatico.
# Executar manualmente ou via Agendador de Tarefas (instalar-tarefa.ps1).

$ErrorActionPreference = 'Stop'

# ── Configuracao ──────────────────────────────────────
$obsidianAutoPost = "G:\Meu Drive\OBSidian\AutoPost\📊 Status.md"
$obsidianObras    = "G:\Meu Drive\OBSidian\Obras\📊 Status.md"
$centralRepo      = "C:\Projetos\central"

# ── Verificacoes iniciais ──────────────────────────────
if (-not (Test-Path $centralRepo)) {
    Write-Host "ERRO: Repo nao encontrado em $centralRepo" -ForegroundColor Red
    Write-Host "Clone o repo primeiro: git clone https://github.com/mathfonta/central.git $centralRepo"
    exit 1
}

$synced = @()
$errors = @()

# ── Copiar AutoPost ────────────────────────────────────
if (Test-Path $obsidianAutoPost) {
    Copy-Item $obsidianAutoPost "$centralRepo\status-autopost.md" -Force
    $synced += "AutoPost"
    Write-Host "OK AutoPost Status.md copiado" -ForegroundColor Green
} else {
    $errors += "AutoPost: arquivo nao encontrado em $obsidianAutoPost"
    Write-Host "AVISO: $($errors[-1])" -ForegroundColor Yellow
}

# ── Copiar Obras ───────────────────────────────────────
if (Test-Path $obsidianObras) {
    Copy-Item $obsidianObras "$centralRepo\status-obras.md" -Force
    $synced += "Obras"
    Write-Host "OK Obras Status.md copiado" -ForegroundColor Green
} else {
    $errors += "Obras: arquivo nao encontrado em $obsidianObras"
    Write-Host "AVISO: $($errors[-1])" -ForegroundColor Yellow
}

# ── Nada para commitar ─────────────────────────────────
if ($synced.Count -eq 0) {
    Write-Host "Nenhum arquivo sincronizado. Verifique se o Google Drive esta montado." -ForegroundColor Red
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
