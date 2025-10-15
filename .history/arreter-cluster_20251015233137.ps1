#!/usr/bin/env pwsh
# ============================================
# Script d'arrêt du cluster MongoDB Shardé
# ============================================

Write-Host "`n╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  🛑 Arrêt du Cluster MongoDB Shardé                     ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

$choice = Read-Host "Voulez-vous supprimer les données ? (o/N)"

if ($choice -eq "o" -or $choice -eq "O") {
    Write-Host "`n⚠️  ATTENTION: Toutes les données seront supprimées!" -ForegroundColor Red
    $confirm = Read-Host "Êtes-vous sûr ? Tapez 'SUPPRIMER' pour confirmer"
    
    if ($confirm -eq "SUPPRIMER") {
        Write-Host "`n🗑️  Arrêt et suppression des volumes..." -ForegroundColor Yellow
        docker-compose down -v
        
        Write-Host "🗑️  Suppression des dossiers de données..." -ForegroundColor Yellow
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue .\principal_a\data\*
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue .\secondaire_a_1\data\*
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue .\secondaire_a_2\data\*
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue .\secondaire_a_3\data\*
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue .\principal_b\data\*
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue .\secondaire_b_1\data\*
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue .\secondaire_b_2\data\*
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue .\secondaire_b_3\data\*
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue .\principal_c\data\*
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue .\secondaire_c_1\data\*
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue .\secondaire_c_2\data\*
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue .\secondaire_c_3\data\*
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue .\historique_1\data\*
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue .\historique_2\data\*
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue .\historique_3\data\*
        
        Write-Host "`n✅ Cluster arrêté et données supprimées" -ForegroundColor Green
    } else {
        Write-Host "`n❌ Annulation de la suppression" -ForegroundColor Yellow
        Write-Host "🛑 Arrêt du cluster sans supprimer les données..." -ForegroundColor Yellow
        docker-compose down
        Write-Host "`n✅ Cluster arrêté (données conservées)" -ForegroundColor Green
    }
} else {
    Write-Host "`n🛑 Arrêt du cluster..." -ForegroundColor Yellow
    docker-compose down
    Write-Host "`n✅ Cluster arrêté (données conservées)" -ForegroundColor Green
}

Write-Host "`n📊 Containers restants:" -ForegroundColor Cyan
docker ps -a | Select-String "mongo|routeur|historique|adminmongo"

Write-Host ""
