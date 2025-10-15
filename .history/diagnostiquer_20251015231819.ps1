# Script PowerShell pour diagnostiquer les problèmes
# Usage: .\diagnostiquer.ps1

Write-Host "🔍 Diagnostic du cluster MongoDB" -ForegroundColor Cyan
Write-Host "================================`n" -ForegroundColor Cyan

Write-Host "📊 1. État des containers:" -ForegroundColor Yellow
docker-compose ps

Write-Host "`n📋 2. Logs du principal (dernières 20 lignes):" -ForegroundColor Yellow
docker-compose logs --tail=20 principal_a

Write-Host "`n📋 3. Logs de secondaire_a_1 (dernières 20 lignes):" -ForegroundColor Yellow
docker-compose logs --tail=20 secondaire_a_1

Write-Host "`n📋 4. Logs du setup-rs:" -ForegroundColor Yellow
docker-compose logs setup-rs

Write-Host "`n🔌 5. Test de connexion au principal:" -ForegroundColor Yellow
docker exec principal_a mongosh --quiet --eval "db.adminCommand('ping')" 2>$null

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Principal répond!" -ForegroundColor Green
    
    Write-Host "`n🔗 6. État du replica set:" -ForegroundColor Yellow
    docker exec principal_a mongosh --quiet --eval "rs.status().members.forEach(m => print(m.name + ' - ' + m.stateStr))" 2>$null
} else {
    Write-Host "❌ Principal ne répond pas!" -ForegroundColor Red
}

Write-Host "`n📁 7. Vérification des volumes:" -ForegroundColor Yellow
$folders = @("principal_a\data", "secondaire_a_1\data", "secondaire_a_2\data", "secondaire_a_3\data")
foreach ($folder in $folders) {
    if (Test-Path $folder) {
        $count = (Get-ChildItem -Path $folder -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
        Write-Host "  $folder : $count fichiers" -ForegroundColor Gray
    } else {
        Write-Host "  $folder : ❌ N'existe pas!" -ForegroundColor Red
    }
}

Write-Host "`n✅ Diagnostic terminé!" -ForegroundColor Green
