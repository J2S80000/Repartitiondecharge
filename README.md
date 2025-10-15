# MongoDB Sharded Cluster - Architecture Complète

## 📊 Vue d'ensemble de l'architecture

Ce projet implémente un **cluster MongoDB shardé** complet avec:
- **3 shards** (replica sets A, B, C) pour la répartition des données
- **1 serveur de configuration** (historique) pour les métadonnées du cluster
- **2 routeurs mongos** pour diriger les requêtes vers les shards appropriés
- **1 interface AdminMongo** pour la gestion graphique

---

## 🏗️ Architecture détaillée

```
                    ┌─────────────┐     ┌─────────────┐
                    │  Routeur 1  │     │  Routeur 2  │
                    │  (mongos)   │     │  (mongos)   │
                    │  :27040     │     │  :27041     │
                    └──────┬──────┘     └──────┬──────┘
                           │                   │
                           └─────────┬─────────┘
                                     │
                    ┌────────────────┴────────────────┐
                    │                                 │
          ┌─────────▼─────────┐          ┌───────────▼──────────┐
          │   Config Server   │          │   AdminMongo :1234   │
          │    (historique)   │          │   Interface Web      │
          │  3 nœuds :27030-32│          └──────────────────────┘
          └─────────┬─────────┘
                    │
        ┌───────────┼───────────┐
        │           │           │
   ┌────▼────┐ ┌───▼────┐ ┌───▼────┐
   │ Shard A │ │Shard B │ │Shard C │
   │         │ │        │ │        │
   │principal│ │principal│ │principal│
   │ :27017  │ │ :27021 │ │ :27025 │
   │         │ │        │ │        │
   │3 second.│ │3 second│ │3 second│
   │27018-20 │ │27022-24│ │27026-28│
   └─────────┘ └────────┘ └────────┘
```

---

## 📦 Composants du cluster

### 🔷 Shard A (replSet_a)
- **principal_a** → Port 27017 (PRIMARY)
- **secondaire_a_1** → Port 27018 (SECONDARY)
- **secondaire_a_2** → Port 27019 (SECONDARY)
- **secondaire_a_3** → Port 27020 (SECONDARY)

### 🔷 Shard B (replSet_b)
- **principal_b** → Port 27021 (PRIMARY)
- **secondaire_b_1** → Port 27022 (SECONDARY)
- **secondaire_b_2** → Port 27023 (SECONDARY)
- **secondaire_b_3** → Port 27024 (SECONDARY)

### 🔷 Shard C (replSet_c)
- **principal_c** → Port 27025 (PRIMARY)
- **secondaire_c_1** → Port 27026 (SECONDARY)
- **secondaire_c_2** → Port 27027 (SECONDARY)
- **secondaire_c_3** → Port 27028 (SECONDARY)

### 📚 Config Server (configReplSet)
- **historique_1** → Port 27030 (Config Server)
- **historique_2** → Port 27031 (Config Server)
- **historique_3** → Port 27032 (Config Server)

### 🔀 Routeurs mongos
- **routeur_1** → Port 27040 (Query Router)
- **routeur_2** → Port 27041 (Query Router)

### 🌐 Interface Web
- **adminmongo** → Port 1234 (http://localhost:1234)

---

## 🚀 Démarrage du cluster

### 1️⃣ Démarrer tous les services
```powershell
docker-compose up -d
```

### 2️⃣ Vérifier l'état du cluster
```powershell
# Vérifier que tous les containers sont actifs
docker-compose ps

# Voir les logs d'initialisation
docker-compose logs setup-sharding
```

### 3️⃣ Vérifier le sharding
```powershell
# Se connecter au routeur
docker exec -it routeur_1 mongosh

# Dans le shell MongoDB :
sh.status()         # État du cluster shardé
sh.getShards()      # Liste des shards
```

---

## 📝 Commandes utiles

### Se connecter aux différents composants

```powershell
# Routeur 1 (point d'entrée principal)
docker exec -it routeur_1 mongosh

# Routeur 2
docker exec -it routeur_2 mongosh

# Shard A (primary)
docker exec -it principal_a mongosh

# Shard B (primary)
docker exec -it principal_b mongosh

# Shard C (primary)
docker exec -it principal_c mongosh

# Config server
docker exec -it historique_1 mongosh --port 27019
```

### Tester le sharding

```powershell
# Se connecter au routeur
docker exec -it routeur_1 mongosh

# Dans le shell MongoDB :
use testdb

# Activer le sharding sur la base
sh.enableSharding("testdb")

# Créer une collection shardée avec clé de sharding
sh.shardCollection("testdb.users", { _id: "hashed" })

# Insérer des données (elles seront automatiquement réparties)
for (let i = 0; i < 10000; i++) {
  db.users.insertOne({ 
    name: "User" + i, 
    age: Math.floor(Math.random() * 80) + 18,
    email: "user" + i + "@example.com"
  })
}

# Vérifier la distribution
sh.status()
db.users.getShardDistribution()
```

### Arrêter le cluster

```powershell
# Arrêt propre
docker-compose down

# Arrêt et suppression des volumes (⚠️ perte de données)
docker-compose down -v
```

---

## 🔍 Monitoring et diagnostic

### Vérifier l'état des replica sets

```powershell
# Replica Set A
docker exec principal_a mongosh --eval "rs.status()" --quiet

# Replica Set B
docker exec principal_b mongosh --eval "rs.status()" --quiet

# Replica Set C
docker exec principal_c mongosh --eval "rs.status()" --quiet

# Config Server
docker exec historique_1 mongosh --port 27019 --eval "rs.status()" --quiet
```

### Voir les logs en temps réel

```powershell
# Tous les services
docker-compose logs -f

# Un service spécifique
docker-compose logs -f routeur_1
docker-compose logs -f principal_a
```

---

## 🎯 Cas d'usage du sharding

### Quand utiliser cette architecture ?

✅ **Avantages du sharding :**
- Répartition horizontale des données (scalabilité)
- Distribution géographique possible
- Haute disponibilité (replica sets)
- Tolérance aux pannes
- Performance améliorée pour gros volumes

📊 **Scénarios idéaux :**
- Bases de données > 100 GB
- Millions de documents
- Trafic important nécessitant plusieurs serveurs
- Besoin de distribution géographique

---

## 🛠️ Configuration avancée

### Changer la clé de sharding

```javascript
// Exemple : sharding par pays
sh.shardCollection("testdb.orders", { country: 1 })

// Sharding par hash (distribution uniforme)
sh.shardCollection("testdb.products", { _id: "hashed" })

// Sharding composé (compound key)
sh.shardCollection("testdb.logs", { userId: 1, timestamp: 1 })
```

### Configurer des zones (tag-aware sharding)

```javascript
// Affecter des tags aux shards
sh.addShardTag("replSet_a", "EU")
sh.addShardTag("replSet_b", "US")
sh.addShardTag("replSet_c", "ASIA")

// Définir des plages de données par zone
sh.addTagRange(
  "testdb.users",
  { country: "FR" }, { country: "FR\xff" },
  "EU"
)
```

---

## 📚 Ressources

- [Documentation MongoDB Sharding](https://docs.mongodb.com/manual/sharding/)
- [MongoDB Replica Sets](https://docs.mongodb.com/manual/replication/)
- [mongos Router](https://docs.mongodb.com/manual/core/sharded-cluster-query-router/)

---

## ⚠️ Notes importantes

1. **Config Server** : Ne jamais supprimer le config server, il contient toutes les métadonnées du cluster
2. **Routeurs** : Toujours passer par les routeurs (mongos) pour les opérations sur le cluster shardé
3. **Backup** : Sauvegarder régulièrement les données et le config server
4. **Production** : En production, activer l'authentification et TLS/SSL

---

## 🐛 Dépannage

### Les containers s'arrêtent immédiatement
```powershell
# Voir les logs d'erreur
docker-compose logs <nom_service>

# Vérifier que les ports ne sont pas déjà utilisés
netstat -ano | findstr "27017"
```

### Le sharding ne fonctionne pas
```powershell
# Vérifier que les shards sont ajoutés
docker exec -it routeur_1 mongosh --eval "sh.status()"

# Relancer l'initialisation du sharding
docker-compose restart setup-sharding
docker-compose logs setup-sharding
```

### Réinitialiser complètement le cluster
```powershell
docker-compose down -v
Remove-Item -Recurse -Force .\*\data\*
docker-compose up -d
```
