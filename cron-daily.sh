# date courante
d=`date +%Y-%m-%d`
YEAR=$(date +%Y)

# récupération fichier du jour
curl -sL 'https://dgal.opendatasoft.com/explore/dataset/export_alimconfiance/download/?format=csv&timezone=Europe/Berlin&use_labels_for_header=true' > export_alimconfiance_$d.csv

# nettoyage ; > , + remise en ordre des colonnes + tri par SIRET
csvcut -d ';' -c APP_Libelle_activite_etablissement,APP_Libelle_etablissement,ods_adresse,Code_postal,Libelle_commune,Libelle_commune,Date_inspection,Synthese_eval_sanit,Agrement,geores,ods_adresse,filtre,Numero_inspection,SIRET export_alimconfiance_$d.csv | csvsort -c SIRET,Numero_inspection > export_alimconfiance.csv

# commit git + push sur github
git commit -a -m "$d"

. ~/.keychain/cquest-Precision-WorkStation-T7500-sh

git push

# on range le fichier pour archive...
mv export_alimconfiance_$d.csv exports/

cd exports
# ajout au fichier compressé d'archives de l'année
7z u ../exports_alim_confiance_$YEAR.7z *.csv
cd -

# envoi sur data.cquest.org
rsync exports* root@192.168.0.72:/local-zfs/opendatarchives/data.cquest.org/alim_confiance/ -az

# envoi vers OpenEventDatabase des nouveaux contrôles
~/.virtualenvs/oedb/bin/python dgal2oedb.py exports/export_alimconfiance_$d.csv
