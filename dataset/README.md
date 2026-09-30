# Dataset ASL Alphabet (épellation)

Jeu d'images pour reconnaître les lettres A–Z, `space`, `del` et `nothing`
(ASL). Le pipeline d'entraînement (`train.py`, `model.py`, …) produit un
CNN-BiLSTM exporté en TFLite.

## Intégration dans MooMoo

Le modèle servi par l'application vit dans **`ml/models/fingerspell/`**
(`model.tflite` + `labels.json`). L'API ML expose :

- `POST /infer/spell` — image + `session_id` → lettre + phrase assemblée
- les images fixes envoyées à `POST /infer` passent aussi par l'épellation

Le traducteur Flutter capture des frames en boucle et forme des phrases
(lettres, espaces, effacement).

## Réentraîner

```bash
cd dataset
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
python train.py
copy outputs\models\asl_lstm_mobile.tflite ..\ml\models\fingerspell\model.tflite
copy outputs\models\labels.json ..\ml\models\fingerspell\labels.json
```

Les images d'entraînement (`asl_alphabet_train/`, ≈1 Go) sont gitignorées.
