# sync-obsidian.ps1
# Copia os Status.md do Obsidian para o repo central e faz push automatico.
# Executar manualmente ou via Agendador de Tarefas (instalar-tarefa.ps1).

$ErrorActionPreference = 'Stop'

# ── Configuracao ──────────────────────────────────────
$obsidianAutoPostDir = "G:\Meu Drive\OBSidian\AutoPost"
$obsidianObrasDir    = "G:\Meu Drive\OBSidian\Obras"
$centralRepo         = "C:\Projetos\central"

# Busca *Status.md na pasta raiz e um nivel abaixo
function Find-StatusMd($dir) {
    if (-not (Test-Path $dir)) { return $null }
    # Busca recursiva limitada a 2 niveis de profundidade
    $file = Get-ChildItem -Path $dir -Filter "*Status.md" -Recurse -Depth 2 -ErrorAction SilentlyContinue | Select-Object -First 1
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
    Write-Host "OK AutoPost: $($autoPostFile.FullName)" -ForegroundColor Green
} else {
    $errors += "AutoPost: nenhum *Status.md encontrado em $obsidianAutoPostDir"
    Write-Host "AVISO: $($errors[-1])" -ForegroundColor Yellow
    # Listar o que existe na pasta para diagnostico
    if (Test-Path $obsidianAutoPostDir) {
        Write-Host "  Arquivos .md encontrados:" -ForegroundColor DarkGray
        Get-ChildItem -Path $obsidianAutoPostDir -Filter "*.md" -Recurse -Depth 1 -ErrorAction SilentlyContinue | Select-Object -First 10 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
    }
}

# ── Copiar Obras ───────────────────────────────────────
$obrasFile = Find-StatusMd $obsidianObrasDir
if ($obrasFile) {
    Copy-Item $obrasFile.FullName "$centralRepo\status-obras.md" -Force
    $synced += "Obras"
    Write-Host "OK Obras: $($obrasFile.FullName)" -ForegroundColor Green
} else {
    $errors += "Obras: nenhum *Status.md encontrado em $obsidianObrasDir"
    Write-Host "AVISO: $($errors[-1])" -ForegroundColor Yellow
}

# ── Nada para sync ─────────────────────────────────────
if ($synced.Count -eq 0) {
    Write-Host "Nenhum arquivo encontrado. Verifique se o Google Drive esta montado." -ForegroundColor Red
    exit 1
}

# ── Git pull + push ────────────────────────────────────
Set-Location $centralRepo

# Sincroniza com origin antes de commitar (evita push rejected)
Write-Host "Sincronizando com GitHub..." -ForegroundColor Cyan
git pull --rebase 2>&1 | Write-Host

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
