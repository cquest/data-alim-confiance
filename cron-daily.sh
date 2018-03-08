# date courante
d=`date +%Y-%m-%d`

# récupération fichier du jour
curl -s 'https://dgal.opendatasoft.com/explore/dataset/export_alimconfiance/download/?format=csv&timezone=Europe/Berlin&use_labels_for_header=true' > export_alimconfiance_$d.csv

# nettoyage ; > , + remise en ordre des colonnes + tri par SIRET
csvcut -d ';' -c APP_Libelle_activite_etablissement,APP_Libelle_etablissement,ods_adresse,Code_postal,Libelle_commune,Libelle_commune,Date_inspection,Synthese_eval_sanit,Agrement,geores,ods_adresse,filtre,Numero_inspection,SIRET export_alimconfiance_$d.csv | csvsort -c SIRET,Numero_inspection > export_alimconfiance.csv

# ajout au fichier compressé d'archive
7z u exports_alim_confiance.7z export_alimconfiance_$d.csv

# commit git + push sur github
git commit -a -m "$d"


. ~/.keychain/cquest-Precision-WorkStation-T7500-sh

git push

# envoi sur scaleway
rsync exports_alim_confiance.7z root@data.cquest.org:/var/www/html/data/alim_confiance/ -a

# envoi vers OpenEventDatabase des nouveaux contrôles
~/.virtualenvs/oedb/bin/python dgal2oedb.py export_alimconfiance_$d.csv

# on range le fichier pour archive...
mv export_alimconfiance_$d.csv exports/
