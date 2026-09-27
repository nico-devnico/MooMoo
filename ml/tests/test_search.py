import random

import pytest

from moomoo_ml.model import DEFAULT_MODEL_CONFIG, merge_config, validate_config
from moomoo_ml.search import hyperband_schedule, sample_config, sample_unique


def test_hyperband_schedule_matches_li_et_al():
    brackets = hyperband_schedule(81, eta=3)
    assert len(brackets) == 5
    first = brackets[0]
    assert [(r.configs, r.epochs) for r in first.rungs] == [(81, 1), (27, 3), (9, 9), (3, 27), (1, 81)]
    assert [(r.configs, r.epochs) for r in brackets[-1].rungs] == [(5, 81)]
    for b in brackets:
        epochs = [r.epochs for r in b.rungs]
        assert epochs == sorted(epochs) and epochs[-1] == 81


def test_max_trials_caps_the_number_of_sampled_configs():
    brackets = hyperband_schedule(27, eta=3, max_trials=12)
    assert sum(b.initial_configs for b in brackets) <= 12


def test_invalid_schedule_arguments():
    with pytest.raises(ValueError):
        hyperband_schedule(0)
    with pytest.raises(ValueError):
        hyperband_schedule(10, eta=1)


def test_sampled_configs_are_valid_and_unique():
    base = merge_config(None)
    rng = random.Random(0)
    seen: set = set()
    configs = sample_unique({}, 15, rng, base, seen)
    assert len(configs) == 15
    for cfg in configs:
        validate_config(cfg)
        assert 1e-4 <= cfg["learning_rate"] <= 3e-3
        assert 0.0 <= cfg["dropout"] <= 0.5
        assert 1 <= len(cfg["lstm_units"]) <= 3


def test_default_architecture_is_the_requested_one():
    assert DEFAULT_MODEL_CONFIG["lstm_units"] == [128, 256, 128]
    cfg = sample_config({"lstm_layers": [2], "lstm_units": [64]}, random.Random(1), merge_config(None))
    assert cfg["lstm_units"] == [64, 64]
