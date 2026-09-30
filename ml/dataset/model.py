"""Architecture CNN-BiLSTM optimisée pour reconnaissance ASL sur mobile."""

from __future__ import annotations

import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers, regularizers

import config


def build_asl_lstm_model(
    input_shape: tuple = config.INPUT_SHAPE,
    num_classes: int = config.NUM_CLASSES,
    l2: float = config.L2_REG,
    dropout: float = config.DROPOUT,
) -> keras.Model:
    """
    CNN spatial léger + BiLSTM temporel.

    Pipeline :
      image (H, W, C)
        → convolutions + pooling (features spatiales)
        → reshape en séquence (timesteps = hauteur restante)
        → BiLSTM (dépendance inter-lignes de la main)
        → Dense softmax (lettre / commande)

    Conçu pour TFLite / app mobile : peu de paramètres, entrée 64×64.
    """
    reg = regularizers.l2(l2)
    inputs = keras.Input(shape=input_shape, name="image")

    x = layers.Rescaling(1.0 / 255.0, name="normalize")(inputs)

    filters = config.CONV_FILTERS
    for i, f in enumerate(filters):
        x = layers.Conv2D(
            f,
            kernel_size=3,
            padding="same",
            use_bias=False,
            kernel_regularizer=reg,
            name=f"conv_{i + 1}",
        )(x)
        x = layers.BatchNormalization(name=f"bn_{i + 1}")(x)
        x = layers.Activation("relu", name=f"relu_{i + 1}")(x)
        x = layers.MaxPooling2D(2, name=f"pool_{i + 1}")(x)
        x = layers.Dropout(dropout * 0.4, name=f"drop_conv_{i + 1}")(x)

    # (batch, h, w, c) → (batch, h, w*c) : chaque ligne = un timestep LSTM
    h = x.shape[1]
    w = x.shape[2]
    c = x.shape[3]
    x = layers.Reshape((h, w * c), name="seq_reshape")(x)

    x = layers.Bidirectional(
        layers.LSTM(
            config.LSTM_UNITS_1,
            return_sequences=True,
            dropout=dropout,
            recurrent_dropout=0.0,
            kernel_regularizer=reg,
            name="lstm_1",
        ),
        name="bilstm_1",
    )(x)
    x = layers.Bidirectional(
        layers.LSTM(
            config.LSTM_UNITS_2,
            return_sequences=False,
            dropout=dropout,
            recurrent_dropout=0.0,
            kernel_regularizer=reg,
            name="lstm_2",
        ),
        name="bilstm_2",
    )(x)

    x = layers.Dense(
        config.DENSE_UNITS,
        activation="relu",
        kernel_regularizer=reg,
        name="dense_fc",
    )(x)
    x = layers.BatchNormalization(name="bn_fc")(x)
    x = layers.Dropout(dropout, name="drop_fc")(x)

    outputs = layers.Dense(num_classes, activation="softmax", name="predictions")(x)

    model = keras.Model(inputs, outputs, name="ASL_CNN_BiLSTM")
    return model


def compile_model(
    model: keras.Model,
    learning_rate: float = config.LEARNING_RATE,
) -> keras.Model:
    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=learning_rate),
        loss="sparse_categorical_crossentropy",
        metrics=[
            "accuracy",
            keras.metrics.SparseTopKCategoricalAccuracy(k=3, name="top3_acc"),
        ],
    )
    return model


if __name__ == "__main__":
    m = compile_model(build_asl_lstm_model())
    m.summary()
    print(f"Paramètres entraînables : {m.count_params():,}")
