# instalar-tarefa.ps1
# Registra o sync-obsidian.ps1 no Agendador de Tarefas do Windows.
# Roda o sync automaticamente a cada 30 minutos enquanto o PC estiver ligado.
# Execute este script UMA vez como Administrador.

$taskName   = "Central-SyncObsidian"
$scriptPath = "C:\Projetos\central\scripts\sync-obsidian.ps1"

# Remove tarefa anterior se existir
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

$action  = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""

# Repete a cada 30 minutos, indefinidamente
$trigger = New-ScheduledTaskTrigger -RepetitionInterval (New-TimeSpan -Minutes 30) -Once -At (Get-Date)

$settings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 5) `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable

Register-ScheduledTask `
    -TaskName $taskName `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -RunLevel Highest `
    -Description "Sincroniza Status.md do Obsidian para o repo central no GitHub" `
    -Force

Write-Host ""
Write-Host "Tarefa '$taskName' registrada com sucesso!" -ForegroundColor Green
Write-Host "Sync automatico a cada 30 minutos."
Write-Host ""
Write-Host "Para testar agora:"
Write-Host "  powershell -File `"$scriptPath`""
Write-Host ""
Write-Host "Para remover a tarefa:"
Write-Host "  Unregister-ScheduledTask -TaskName '$taskName' -Confirm:`$false"
