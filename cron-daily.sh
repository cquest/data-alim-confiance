# date courante
d=`date +%Y-%m-%d`

# récupération fichier du jour
curl -s 'https://dgal.opendatasoft.com/explore/dataset/export_alimconfiance/download/?format=csv&timezone=Europe/Berlin&use_labels_for_header=true' > export_alimconfiance_$d.csv

# nettoyage ; > , + suppression date extraction + tri par SIRET
csvcut -d ';' -C Date_extraction export_alimconfiance_$d.csv | csvsort -c SIRET > export_alimconfiance.csv

# commit git + push sur github
git commit -a -m "$d"
git push

