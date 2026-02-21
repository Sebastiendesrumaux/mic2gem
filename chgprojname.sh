#!/bin/bash

# Vérification du nombre de paramètres
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <ancien_texte> <nouveau_texte>"
    exit 1
fi

ANCIEN=$1
NOUVEAU=$2

# Message de courtoisie pour confirmer l'action
echo "Remplacement de '$ANCIEN' par '$NOUVEAU' dans toute l'arborescence..."

# -type f : uniquement les fichiers
# -exec : exécute la commande sed sur chaque fichier trouvé
# sed -i : modification "in-place" (directement dans le fichier)
# 's/ancien/nouveau/g' : substitution globale

find . -type f -not -name "$(basename "$0")" -exec sed -i "s/$ANCIEN/$NOUVEAU/g" {} +

echo "Opération terminée avec succès."

