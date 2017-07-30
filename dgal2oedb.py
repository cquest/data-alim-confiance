import sys
import csv
import sqlite3
import requests
import json
import hashlib

# adresse de l'API
api ='http://api.openeventdatabase.org'

# base sqlite pour suivre l'évolution des événements d'un run au suivant
sql = sqlite3.connect('dgal.db')
db = sql.cursor()
db.execute('''CREATE TABLE IF NOT EXISTS events (id text, numero text,
  quand date, siret text, hash text)''')

with open(sys.argv[1]) as csv_file:
    dgal = csv.DictReader(csv_file, delimiter=';')
    for controle in dgal:
        e = dict()
        if 'Libelle_commune' in controle and 'Code_postal' in controle and 'ods_adresse' in controle:
            e['where:address'] = '%s, %s %s, France' % (controle['ods_adresse'],controle['Code_postal'],controle['Libelle_commune'])
        elif 'Libelle_commune' in controle:
            e['where:address'] = controle['Libelle_commune'] + ', France'
        elif 'Localite' in controle:
            e['where:address'] = controle['Localite'] + ', France'
        e['name'] = controle['APP_Libelle_etablissement']
        e['when'] = controle['Date_inspection']
        e['label'] = controle['APP_Libelle_etablissement']
        if 'APP_Libelle_activite_etablissement' in controle:
            e['label'] = '%s - %s : %s le %s/%s/%s' % (e['label'], controle['APP_Libelle_activite_etablissement'],controle['Synthese_eval_sanit'], controle['Date_inspection'][8:10], controle['Date_inspection'][5:7], controle['Date_inspection'][0:4])
        if 'SIRET' in controle:
            e['ref:FR:SIRET'] = controle['SIRET']
        e['health:check:level:fr']=controle['Synthese_eval_sanit']
        e['health:check:level'] = ['A corriger de manière urgente',
        'A améliorer','Satisfaisant','Très satisfaisant'].index(controle['Synthese_eval_sanit'])
        e['what'] = 'health.check.dgal.alim_confiance.' + controle['APP_Libelle_activite_etablissement'].replace(' ','_')
        if 'Agrement' in controle and controle['Agrement'] != '':
            e['what'] = e['what'] + '.' + controle['Agrement']
        e['type'] = 'observed'
        e['source'] = 'https://www.data.gouv.fr/fr/datasets/5593aab9c751df35d8a453ba'
        e['source:id'] = controle['Numero_inspection']
        latlon = controle['geores'].replace(',','').split(' ')
        latlon[0] = float(latlon[0]+'0')
        if len(latlon)>1:
            latlon[1] = float(latlon[1]+'0')
        else:
            latlon.insert(0,0)

        g = dict(type='Feature',properties=e, geometry = dict(type='Point',coordinates=[latlon[1],latlon[0]]))
        # l'événement existe déjà ? on le met à jour...
        db.execute('SELECT id FROM events WHERE numero = ?',(controle['Numero_inspection'],))
        last = db.fetchone()
        if last is None:
            # a-t-on un ancien contrôle pour cet établissement ?
            if 'SIRET' in controle:
                db.execute('SELECT id FROM events WHERE siret = ? ORDER BY quand DESC LIMIT 1',(controle['SIRET'],))
                last = db.fetchone()
            else:
                last = None
            if last is not None:
                e['previous'] = last[0]
                e['previous_url'] = api+'/event/'+last[0]
            # on ajoute le nouveau contrôle
            r = requests.post(api+'/event', data = json.dumps(g))
            event = json.loads(r.text)
            if 'duplicate' in event:
                event['id']=event['duplicate']
            print(r.text)
            if last is not None:
                # mise à jour de l'ancien contrôle pour lien avec le nouveau
                old = dict(properties=dict(next=event['id'], next_url=api+'/event/'+event['id']))
            db.execute("INSERT INTO events VALUES ( ? , ? , ? , ? , ? )", (event['id'], controle['Numero_inspection'], controle['Date_inspection'], controle['SIRET'],''))

        sql.commit()

db.close()
