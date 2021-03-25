# BAO1
Boite à outils 1

Cette BAO1 extrait les titre et description du fil RSS du monde pour l'année complete 2020.
2 sorties : format txt et xml

Voici 4 versions de la BAO1 utilisant 4 méthodes differentes:

2 versions regexp only :
- filtrage des doublons avec hash (dictionnaire)
- filtrage des doublons avec uniq (fonction importée de List::MoreUtils)

2 versions avec le module XML::RSS:
- filtrage des doublons avec hash (dictionnaire)
- filtrage des doublons avec uniq (fonction importée de List::MoreUtils)

Fonctionnement :

# --------------------------------------------------------------------------------
# $ARGV[0] = repertoire dans lequel chercher les fichiers xml rss
# $ARGV[1] = code de la catégorie
# --------------------------------------------------------------------------------

Exemple : 
perl bao_regexp.pl 2020 3208

Le resultat XML de sortie est visible dans le fichier une.xml
