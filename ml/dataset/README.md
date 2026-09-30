# Dataset ASL Alphabet (épellation)

Jeu d'images pour reconnaître les lettres A–Z, `space`, `del` et `nothing`
(ASL). Le pipeline d'entraînement (`train.py`, `model.py`, …) produit un
CNN-BiLSTM exporté en TFLite.

Ce dossier fait partie de **`ml/`** : données, entraînement et service
d'inférence forment une seule unité.

## Intégration dans MooMoo

Le modèle servi par l'application vit dans **`ml/models/fingerspell/`**
(`model.tflite` + `labels.json`, versions sous `versions/`). L'API ML expose :

- `POST /infer/spell` — image + `session_id` → lettre + phrase assemblée
- `GET/POST /fingerspell/models*` — liste, détail et activation (admin)
- les images fixes envoyées à `POST /infer` passent aussi par l'épellation

Le traducteur Flutter capture des frames en boucle et forme des phrases
(lettres, espaces, effacement).

## Réentraîner

```bash
cd ml/dataset
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
python train.py
# Copier vers une nouvelle version du registre fingerspell :
mkdir ..\models\fingerspell\versions\asl-lstm-v2
copy outputs\models\asl_lstm_mobile.tflite ..\models\fingerspell\versions\asl-lstm-v2\model.tflite
copy outputs\models\labels.json ..\models\fingerspell\versions\asl-lstm-v2\labels.json
```

Puis activer la version via l'onglet admin **Épellation** ou :

```bash
curl -X POST http://127.0.0.1:8000/fingerspell/models/asl-lstm-v2/activate
```

Les images d'entraînement (`asl_alphabet_train/`, ≈1 Go) sont gitignorées.
