"""MooMoo sign recognition training pipeline.

Dataset -> analysis -> MediaPipe Holistic landmarks -> sequences [T, F]
-> augmentation -> signer-independent split -> LSTM -> Hyperband search
-> evaluation -> model registry -> TensorFlow Lite.
"""

__version__ = "1.0.0"
