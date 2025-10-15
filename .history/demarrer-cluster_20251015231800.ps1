# Script PowerShell pour démarrer le cluster MongoDB complet
# Usage: .\demarrer-cluster.ps1

Write-Host "🧹 Nettoyage des anciens containers..." -ForegroundColor Cyan
docker-compose down -v

Write-Host "`n📁 Création des dossiers de données..." -ForegroundColor Cyan
$folders = @(
    ".\principal_a\data",
    ".\secondaire_a_1\data",
    ".\secondaire_a_2\data",
    ".\secondaire_a_3\data"
)

foreach ($folder in $folders) {
    if (Test-Path $folder) {
        Write-Host "  ✓ Nettoyage: $folder" -ForegroundColor Yellow
        Remove-Item -Path "$folder\*" -Recurse -Force -ErrorAction SilentlyContinue
    } else {
        Write-Host "  ✓ Création: $folder" -ForegroundColor Green
        New-Item -ItemType Directory -Force -Path $folder | Out-Null
    }
}

Write-Host "`n🚀 Démarrage de TOUS les services..." -ForegroundColor Cyan
docker-compose up -d

Write-Host "`n⏳ Attente du démarrage des containers (15 secondes)..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

Write-Host "`n📊 État des containers:" -ForegroundColor Cyan
docker-compose ps

Write-Host "`n🔍 Vérification de l'état du replica set..." -ForegroundColor Cyan
Write-Host "Connexion au principal pour vérifier rs.status()..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

docker exec -it principal_a mongosh --quiet --eval "rs.status()" 2>$null

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Cluster MongoDB opérationnel!" -ForegroundColor Green
    Write-Host "`nAccès:" -ForegroundColor Cyan
    Write-Host "  • Principal:       localhost:27017" -ForegroundColor White
    Write-Host "  • Secondaire 1:    localhost:27018" -ForegroundColor White
    Write-Host "  • Secondaire 2:    localhost:27019" -ForegroundColor White
    Write-Host "  • Secondaire 3:    localhost:27020" -ForegroundColor White
    Write-Host "  • AdminMongo UI:   http://localhost:1234" -ForegroundColor White
    Write-Host "`nCommandes utiles:" -ForegroundColor Cyan
    Write-Host "  docker exec -it principal_a mongosh" -ForegroundColor Gray
    Write-Host "  docker-compose logs -f principal_a" -ForegroundColor Gray
    Write-Host "  docker-compose logs -f secondaire_a_1" -ForegroundColor Gray
} else {
    Write-Host "`n⚠️  Le replica set n'est pas encore initialisé." -ForegroundColor Yellow
    Write-Host "Attendez 30 secondes puis vérifiez avec:" -ForegroundColor Yellow
    Write-Host "  docker exec -it principal_a mongosh --eval 'rs.status()'" -ForegroundColor Gray
}

Write-Host "`n📋 Logs du setup (si erreur):" -ForegroundColor Cyan
docker-compose logs setup-rs 2>$null
