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
---

## ✅ TESTS ET VALIDATION

Cette section documente les tests réalisés pour valider le fonctionnement complet du cluster shardé.

### 📋 Test 1 : Import de données réelles (431 livres)

**Objectif** : Démontrer la distribution automatique des données sur les 3 shards.

#### Étape 1 : Activation du sharding sur la base
```powershell
docker exec routeur_1 mongosh --quiet --eval "sh.enableSharding('paris')"
```

#### Étape 2 : Sharding de la collection avec clé hashed
```powershell
docker exec routeur_1 mongosh --quiet --eval "sh.shardCollection('paris.books', {_id: 'hashed'})"
```

#### Étape 3 : Import des données VIA LE ROUTEUR
```powershell
# Copier le fichier JSON vers le routeur
docker cp "C:\Users\jessy\Documents\books.json" routeur_1:/tmp/books.json

# Importer via mongoimport
docker exec routeur_1 mongoimport --db paris --collection books --file /tmp/books.json
```

**Résultat** :
```
2025-10-16T11:29:43.903+0000    connected to: mongodb://localhost/
2025-10-16T11:29:43.997+0000    431 document(s) imported successfully. 0 document(s) failed to import.
```

⚠️ **IMPORTANT** : Toujours importer via le **routeur** (mongos), jamais directement sur un shard !

#### Étape 4 : Vérification de la distribution des données
```powershell
docker exec routeur_1 mongosh --quiet --eval "use paris" --eval "db.books.getShardDistribution()"
```

**Résultat obtenu** :
```
Shard replSet_c :
  data: '137KiB'
  docs: 130 (30.16%)
  chunks: 1

Shard replSet_a :
  data: '190KiB'
  docs: 150 (34.80%)
  chunks: 1

Shard replSet_b :
  data: '176KiB'
  docs: 151 (35.03%)
  chunks: 1

Totals :
  data: '505KiB'
  docs: 431
  chunks: 3
```

✅ **Validation** : Les 431 documents sont **équitablement répartis** sur les 3 shards (~33% chacun).

---

### 🗄️ Test 2 : Vérification des Config Servers (Historique)

**Objectif** : Confirmer que les métadonnées du cluster sont bien enregistrées et répliquées sur les 3 config servers.

#### Vérification sur historique_1
```powershell
docker exec historique_1 mongosh --port 27019 --quiet --eval "use config" --eval "print('Bases shardees enregistrees:'); db.databases.find().forEach(d => print('  - ' + d._id + ' (primary: ' + d.primary + ')'))"
```

**Résultat** :
```
Bases shardees enregistrees:
  - paris (primary: replSet_b)
```

#### Vérification sur historique_2
```powershell
docker exec historique_2 mongosh --port 27019 --quiet --eval "use config" --eval "print('Bases shardees enregistrees:'); db.databases.find().forEach(d => print('  - ' + d._id + ' (primary: ' + d.primary + ')'))"
```

**Résultat** :
```
Bases shardees enregistrees:
  - paris (primary: replSet_b)
```

#### Vérification sur historique_3
```powershell
docker exec historique_3 mongosh --port 27019 --quiet --eval "use config" --eval "print('Bases shardees enregistrees:'); db.databases.find().forEach(d => print('  - ' + d._id + ' (primary: ' + d.primary + ')'))"
```

**Résultat** :
```
Bases shardees enregistrees:
  - paris (primary: replSet_b)
```

✅ **Validation** : Les métadonnées sont **identiques sur les 3 config servers**, prouvant la réplication fonctionnelle.

**Note** : `primary: replSet_b` signifie que replSet_b est le "primary shard" pour les collections **non shardées** de cette base. Cela n'affecte PAS la distribution des collections shardées comme `paris.books`.

---

### 🔄 Test 3 : Failover automatique (Haute disponibilité)

**Objectif** : Démontrer qu'en cas de panne du PRIMARY, un SECONDARY est automatiquement promu.

#### État initial : principal_a est PRIMARY
```powershell
docker exec -it principal_a mongosh
```

**Résultat** :
```
Connecting to: mongodb://127.0.0.1:27017/?directConnection=true
Using MongoDB: 8.0.13

replSet_a [direct: primary] test>
```

✅ `principal_a` est bien PRIMARY du replica set `replSet_a`.

#### Simulation de panne
```powershell
# Arrêter le container principal_a
docker stop principal_a

# Attendre l'élection (~10-15 secondes)
Start-Sleep -Seconds 15
```

#### Vérification : un SECONDARY devient PRIMARY
```powershell
docker exec -it secondaire_a_1 mongosh
```

**Résultat après élection** :
```
Connecting to: mongodb://127.0.0.1:27017/?directConnection=true
Using MongoDB: 8.0.13

replSet_a [direct: primary] test>
```

✅ **Validation** : `secondaire_a_1` a été **automatiquement promu PRIMARY** !

#### Vérification du statut du replica set
```powershell
docker exec secondaire_a_1 mongosh --eval "rs.status()" --quiet | Select-String "stateStr"
```

**Résultat attendu** :
```
stateStr: 'DOWN'       ← principal_a (arrêté)
stateStr: 'PRIMARY'    ← secondaire_a_1 (nouveau PRIMARY)
stateStr: 'SECONDARY'  ← secondaire_a_2
stateStr: 'SECONDARY'  ← secondaire_a_3
```

#### Restauration
```powershell
# Redémarrer principal_a
docker start principal_a

# Il redeviendra SECONDARY automatiquement
# (ou PRIMARY si vous le configurez avec priority plus élevée)
```

✅ **Conclusion** : Le cluster tolère la **panne d'un nœud par replica set** sans interruption de service.

#### Test approfondi : Réplication et restrictions d'écriture

**Contexte** : `principal_a` est arrêté, `secondaire_a_1` est devenu PRIMARY.

##### 1. Vérifier les données sur le nouveau PRIMARY
```powershell
docker exec -it secondaire_a_1 mongosh
```

```javascript
use paris
db.books.countDocuments()
// Résultat : 150
```

✅ Les **150 livres** du shard A sont toujours accessibles !

##### 2. Vérifier la réplication sur les SECONDARY
```powershell
docker exec -it secondaire_a_2 mongosh
```

```javascript
use paris
db.books.countDocuments()
// Résultat : 150
```

✅ Les données sont **parfaitement répliquées** sur tous les nœuds.

##### 3. Afficher quelques livres
```javascript
db.books.find({}, { _id: 1, title: 1 }).limit(5)
```

**Résultat** :
```javascript
[
  { _id: 29, title: 'jQuery in Action' },
  { _id: 63, title: 'POJOs in Action' },
  { _id: 67, title: 'Wicket in Action' },
  { _id: 72, title: 'SCWCD Exam Study Kit Second Edition' },
  { _id: 132, title: 'Up to Speed with Swing, Second Edition' }
]
```

##### 4. Tentative de suppression sur un SECONDARY (❌ ÉCHOUE)
```javascript
// Toujours connecté sur secondaire_a_2 (SECONDARY)
db.books.deleteOne({ title: "Wicket in Action" })
```

**Résultat** :
```
MongoServerError[NotWritablePrimary]: not primary
```

⚠️ **Règle importante** : Les **écritures sont INTERDITES** sur les SECONDARY !
- Les SECONDARY sont en **lecture seule** (read-only)
- Seul le PRIMARY accepte les écritures

##### 5. Suppression réussie sur le PRIMARY
```powershell
# Se connecter au PRIMARY actuel (secondaire_a_1)
docker exec -it secondaire_a_1 mongosh
```

```javascript
use paris
db.books.deleteOne({ title: "Wicket in Action" })
```

**Résultat** :
```javascript
{ acknowledged: true, deletedCount: 1 }
```

✅ Suppression réussie sur le PRIMARY !

##### 6. Vérification du comptage après suppression
```javascript
db.books.countDocuments()
// Résultat : 149 (150 - 1)
```

##### 7. Vérification de la réplication de la suppression
```powershell
docker exec -it secondaire_a_2 mongosh
```

```javascript
use paris
db.books.countDocuments()
// Résultat : 149
```

✅ La **suppression est automatiquement répliquée** sur tous les SECONDARY !

**Leçons apprises** :
- 🔒 **Écriture** : Uniquement sur PRIMARY
- 📖 **Lecture** : PRIMARY + tous les SECONDARY (avec `rs.secondaryOk()` si besoin)
- 🔄 **Réplication** : Automatique et instantanée (quelques millisecondes)
- 🚀 **Failover** : Promotion automatique d'un SECONDARY en PRIMARY

---

### 📊 Test 4 : Requêtes via le routeur

**Objectif** : Vérifier que les requêtes passent correctement par le routeur et interrogent les bons shards.

#### Compter tous les documents
```powershell
docker exec routeur_1 mongosh --quiet --eval "use paris" --eval "db.books.countDocuments()"
```

**Résultat** : `431` (le routeur interroge les 3 shards et additionne)

#### Rechercher un document spécifique
```powershell
docker exec routeur_1 mongosh --quiet --eval "use paris" --eval "db.books.findOne()"
```

**Résultat** : Retourne 1 document (le routeur va chercher sur UN seul shard grâce au hash de `_id`)

#### Vérifier la présence des données sur chaque shard individuellement
```powershell
# Sur shard A
docker exec principal_a mongosh --quiet --eval "use paris" --eval "db.books.countDocuments()"
# Résultat : 150

# Sur shard B
docker exec principal_b mongosh --quiet --eval "use paris" --eval "db.books.countDocuments()"
# Résultat : 151

# Sur shard C
docker exec principal_c mongosh --quiet --eval "use paris" --eval "db.books.countDocuments()"
# Résultat : 130
```

✅ **Total** : 150 + 151 + 130 = **431 documents** ✓

---

### 🧪 Script de test automatique

Exécutez le script PowerShell fourni pour tester automatiquement les config servers :

```powershell
.\test_historique.ps1
```

Ce script vérifie :
- ✅ Statut des 3 config servers (historique_1/2/3)
- ✅ État du replica set configReplSet (1 PRIMARY + 2 SECONDARY)
- ✅ Présence des 3 shards dans les métadonnées
- ✅ Collections du cluster dans `config` database
- ✅ Réplication entre les config servers
- ✅ Connectivité individuelle de chaque serveur

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
