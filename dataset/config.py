"""Configuration centrale du projet ASL LSTM."""

from pathlib import Path

# Chemins
ROOT_DIR = Path(__file__).resolve().parent
TRAIN_DIR = ROOT_DIR / "asl_alphabet_train" / "asl_alphabet_train"
TEST_DIR = ROOT_DIR / "asl_alphabet_test" / "asl_alphabet_test"
OUTPUT_DIR = ROOT_DIR / "outputs"
MODELS_DIR = OUTPUT_DIR / "models"
PLOTS_DIR = OUTPUT_DIR / "plots"
REPORTS_DIR = OUTPUT_DIR / "reports"

# Classes ASL (ordre alphabétique des dossiers)
CLASSES = [
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
    "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
    "del", "nothing", "space",
]
NUM_CLASSES = len(CLASSES)
CLASS_TO_IDX = {c: i for i, c in enumerate(CLASSES)}
IDX_TO_CLASS = {i: c for i, c in enumerate(CLASSES)}

# Entrée modèle — compact pour mobile
IMG_SIZE = 64
CHANNELS = 3
INPUT_SHAPE = (IMG_SIZE, IMG_SIZE, CHANNELS)

# Données (sous-échantillon stratifié : équilibre précision / temps CPU)
MAX_PER_CLASS = 1000  # 1000 × 29 = 29 000 images
VAL_SPLIT = 0.15
TEST_SPLIT = 0.10
RANDOM_SEED = 42

# Entraînement
BATCH_SIZE = 64
EPOCHS = 40
LEARNING_RATE = 1e-3
MIN_LEARNING_RATE = 1e-6
L2_REG = 1e-4
DROPOUT = 0.35
LSTM_UNITS_1 = 128
LSTM_UNITS_2 = 64
CONV_FILTERS = (32, 64, 96)
DENSE_UNITS = 128

# Callbacks anti sur/sous-apprentissage
EARLY_STOP_PATIENCE = 8
REDUCE_LR_PATIENCE = 3
REDUCE_LR_FACTOR = 0.5

# Augmentation (légère : préserver la géométrie des signes)
AUGMENT = True
