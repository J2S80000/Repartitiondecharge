#! /bin/bash
echo ************************************
echo * Initialisation du replica set *
echo ************************************

sleep 10 | echo "Attente de 10 secondes pour s'assurer que mongod est bien lancé"
mongo mongodb://principal_a:27017 replicaSet_a --eval 'rs.initiate({
  _id: "replSet_a",
  members: [
    { _id: 0, host: "principal_a:27017" },
    { _id: 1, host: "secondaire_a1:27018" },
    { _id: 2, host: "secondaire_a2:27019" }
  ]
})'