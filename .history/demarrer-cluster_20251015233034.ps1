#!/usr/bin/env pwsh
# ============================================
# Script de démarrage du cluster MongoDB Shardé
# ============================================

Write-Host "`n╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  🚀 Démarrage du Cluster MongoDB Shardé                 ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Vérifier que Docker est en cours d'exécution
Write-Host "🔍 Vérification de Docker..." -ForegroundColor Yellow
try {
    docker info | Out-Null
    Write-Host "✅ Docker est actif`n" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker n'est pas en cours d'exécution. Veuillez démarrer Docker Desktop." -ForegroundColor Red
    exit 1
}

# Arrêter les anciens containers s'ils existent
Write-Host "🛑 Arrêt des containers existants..." -ForegroundColor Yellow
docker-compose down 2>&1 | Out-Null
Write-Host "✅ Containers arrêtés`n" -ForegroundColor Green

# Créer les dossiers de données si nécessaire
Write-Host "📁 Création de la structure de dossiers..." -ForegroundColor Yellow
$folders = @(
    "principal_a/data", "secondaire_a_1/data", "secondaire_a_2/data", "secondaire_a_3/data",
    "principal_b/data", "secondaire_b_1/data", "secondaire_b_2/data", "secondaire_b_3/data",
    "principal_c/data", "secondaire_c_1/data", "secondaire_c_2/data", "secondaire_c_3/data",
    "historique_1/data", "historique_2/data", "historique_3/data"
)

foreach ($folder in $folders) {
    New-Item -ItemType Directory -Force -Path $folder | Out-Null
}
Write-Host "✅ Tous les dossiers créés`n" -ForegroundColor Green

# Démarrer le cluster
Write-Host "🚀 Démarrage des services Docker Compose..." -ForegroundColor Yellow
docker-compose up -d

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Cluster démarré avec succès!`n" -ForegroundColor Green
    
    Write-Host "⏳ Attente de l'initialisation (30 secondes)..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
    
    # Afficher l'état des containers
    Write-Host "`n📊 État des containers:" -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan
    docker-compose ps
    
    # Vérifier les logs d'initialisation
    Write-Host "`n📋 Logs du setup du sharding:" -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan
    docker-compose logs setup-sharding
    
    # Informations de connexion
    Write-Host "`n╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║  ✅ Cluster MongoDB Shardé prêt à l'emploi!              ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════╝`n" -ForegroundColor Green
    
    Write-Host "🔗 Points d'accès:" -ForegroundColor Cyan
    Write-Host "   • Routeur 1:      " -NoNewline; Write-Host "localhost:27040" -ForegroundColor Yellow
    Write-Host "   • Routeur 2:      " -NoNewline; Write-Host "localhost:27041" -ForegroundColor Yellow
    Write-Host "   • AdminMongo:     " -NoNewline; Write-Host "http://localhost:1234" -ForegroundColor Yellow
    
    Write-Host "`n📦 Shards disponibles:" -ForegroundColor Cyan
    Write-Host "   • Shard A (replSet_a): Ports 27017-27020" -ForegroundColor White
    Write-Host "   • Shard B (replSet_b): Ports 27021-27024" -ForegroundColor White
    Write-Host "   • Shard C (replSet_c): Ports 27025-27028" -ForegroundColor White
    
    Write-Host "`n📚 Config Server (historique):" -ForegroundColor Cyan
    Write-Host "   • Ports 27030-27032" -ForegroundColor White
    
    Write-Host "`n💡 Commandes utiles:" -ForegroundColor Cyan
    Write-Host "   # Se connecter au routeur" -ForegroundColor Gray
    Write-Host "   docker exec -it routeur_1 mongosh`n" -ForegroundColor White
    
    Write-Host "   # Vérifier l'état du cluster" -ForegroundColor Gray
    Write-Host "   docker exec -it routeur_1 mongosh --eval 'sh.status()'`n" -ForegroundColor White
    
    Write-Host "   # Voir les logs en temps réel" -ForegroundColor Gray
    Write-Host "   docker-compose logs -f`n" -ForegroundColor White
    
    Write-Host "   # Arrêter le cluster" -ForegroundColor Gray
    Write-Host "   .\arreter-cluster.ps1`n" -ForegroundColor White
    
    Write-Host "📖 Consultez README.md pour plus d'informations`n" -ForegroundColor Cyan
    
} else {
    Write-Host "`n❌ Erreur lors du démarrage du cluster" -ForegroundColor Red
    Write-Host "Consultez les logs avec: docker-compose logs`n" -ForegroundColor Yellow
    exit 1
}
