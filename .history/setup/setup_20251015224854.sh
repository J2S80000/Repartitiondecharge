#! /bin/bash
echo ************************************
echo * Initialisation du replica set *
echo ************************************

sleep 10 | echo "Attente de 10 secondes pour s'assurer que mongod est bien lancé"
mongo mongodb://m