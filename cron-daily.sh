# date courante
d=`date +%Y-%m-%d`

# récupération fichier du jour
curl -s 'https://dgal.opendatasoft.com/explore/dataset/export_alimconfiance/download/?format=csv&timezone=Europe/Berlin&use_labels_for_header=true' > export_alimconfiance_$d.csv

# nettoyage ; > , + remise en ordre des colonnes + tri par SIRET
csvcut -d ';' -c APP_Libelle_activite_etablissement,APP_Libelle_etablissement,ods_adresse,Code_postal,Libelle_commune,Libelle_commune,Date_inspection,Synthese_eval_sanit,Agrement,geores,ods_adresse,filtre,Numero_inspection,SIRET export_alimconfiance_$d.csv | csvsort -c SIRET,Numero_inspection > export_alimconfiance.csv

# commit git + push sur github
git commit -a -m "$d"
git push

