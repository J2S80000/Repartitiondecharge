# Script PowerShell pour arrêter proprement le cluster
# Usage: .\arreter-cluster.ps1

Write-Host "🛑 Arrêt de tous les containers..." -ForegroundColor Yellow
docker-compose down

Write-Host "`n✅ Cluster arrêté!" -ForegroundColor Green
Write-Host "`nPour redémarrer: .\demarrer-cluster.ps1" -ForegroundColor Cyan
