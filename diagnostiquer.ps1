#!/usr/bin/env pwsh
# ============================================
# Script de diagnostic du cluster MongoDB Shardé
# ============================================

Write-Host "`n╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  🔍 Diagnostic du Cluster MongoDB Shardé                ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Fonction pour afficher un titre de section
function Write-Section {
    param([string]$Title)
    Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host " $Title" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════`n" -ForegroundColor Cyan
}

# 1. État des containers
Write-Section "📦 État des containers"
docker-compose ps

# 2. État du sharding
Write-Section "🔀 État du cluster shardé"
try {
    docker exec -it routeur_1 mongosh --quiet --eval "
    print('Shards enregistrés:');
    printjson(sh.status());
    " 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠️  Le routeur n'est pas accessible ou le sharding n'est pas initialisé" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Impossible de se connecter au routeur" -ForegroundColor Red
}

# 3. État des replica sets
Write-Section "🔷 Replica Set A (Shard A)"
try {
    docker exec principal_a mongosh --quiet --eval "
    var status = rs.status();
    print('État: ' + status.ok);
    print('Set: ' + status.set);
    status.members.forEach(function(m) {
        print(m.name + ' → ' + m.stateStr);
    });
    " 2>$null
} catch {
    Write-Host "❌ Replica Set A non accessible" -ForegroundColor Red
}

Write-Section "🔷 Replica Set B (Shard B)"
try {
    docker exec principal_b mongosh --quiet --eval "
    var status = rs.status();
    print('État: ' + status.ok);
    print('Set: ' + status.set);
    status.members.forEach(function(m) {
        print(m.name + ' → ' + m.stateStr);
    });
    " 2>$null
} catch {
    Write-Host "❌ Replica Set B non accessible" -ForegroundColor Red
}

Write-Section "🔷 Replica Set C (Shard C)"
try {
    docker exec principal_c mongosh --quiet --eval "
    var status = rs.status();
    print('État: ' + status.ok);
    print('Set: ' + status.set);
    status.members.forEach(function(m) {
        print(m.name + ' → ' + m.stateStr);
    });
    " 2>$null
} catch {
    Write-Host "❌ Replica Set C non accessible" -ForegroundColor Red
}

Write-Section "📚 Config Server (historique)"
try {
    docker exec historique_1 mongosh --port 27019 --quiet --eval "
    var status = rs.status();
    print('État: ' + status.ok);
    print('Set: ' + status.set);
    status.members.forEach(function(m) {
        print(m.name + ' → ' + m.stateStr);
    });
    " 2>$null
} catch {
    Write-Host "❌ Config Server non accessible" -ForegroundColor Red
}

# 4. Statistiques du cluster
Write-Section "📊 Statistiques du cluster"
try {
    docker exec -it routeur_1 mongosh --quiet --eval "
    print('Bases de données:');
    db.adminCommand('listDatabases').databases.forEach(function(db) {
        print('  • ' + db.name + ' (' + (db.sizeOnDisk / 1024 / 1024).toFixed(2) + ' MB)');
    });
    
    print('\nCollections shardées:');
    var dbs = db.adminCommand('listDatabases').databases;
    dbs.forEach(function(database) {
        if (database.name !== 'admin' && database.name !== 'config' && database.name !== 'local') {
            var collections = db.getSiblingDB(database.name).getCollectionNames();
            collections.forEach(function(coll) {
                var stats = db.getSiblingDB('config').collections.findOne({_id: database.name + '.' + coll});
                if (stats) {
                    print('  • ' + database.name + '.' + coll);
                    print('    Clé: ' + JSON.stringify(stats.key));
                }
            });
        }
    });
    " 2>$null
} catch {
    Write-Host "⚠️  Pas encore de données dans le cluster" -ForegroundColor Yellow
}

# 5. Logs récents des services d'initialisation
Write-Section "📋 Logs d'initialisation"
Write-Host "Config Server:" -ForegroundColor Cyan
docker-compose logs --tail=5 setup-config 2>$null

Write-Host "`nSharding:" -ForegroundColor Cyan
docker-compose logs --tail=10 setup-sharding 2>$null

# 6. Utilisation des ressources
Write-Section "💻 Utilisation des ressources"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" | Select-String "mongo|routeur|historique"

# Résumé
Write-Section "✅ Diagnostic terminé"
Write-Host "💡 Commandes utiles:" -ForegroundColor Cyan
Write-Host "   • Logs en temps réel:    " -NoNewline; Write-Host "docker-compose logs -f" -ForegroundColor White
Write-Host "   • Se connecter:          " -NoNewline; Write-Host "docker exec -it routeur_1 mongosh" -ForegroundColor White
Write-Host "   • État du sharding:      " -NoNewline; Write-Host "docker exec -it routeur_1 mongosh --eval 'sh.status()'" -ForegroundColor White
Write-Host ""
