from moomoo_ml.split import split_entries


def _entries(signers: int, per_signer: int, labels=("a", "b", "c")):
    out = []
    for s in range(signers):
        for k in range(per_signer):
            out.append({"label": labels[k % len(labels)], "signer": f"signer-{s}",
                        "fingerprint": f"fp-{s}-{k}"})
    return out


def test_signer_independent_split_has_no_signer_leakage():
    entries = _entries(signers=8, per_signer=9)
    splits, report = split_entries(entries, seed=1)
    assert report["signer_independent"] is True
    seen = {k: {entries[i]["signer"] for i in v} for k, v in splits.items()}
    assert not (seen["train"] & seen["val"])
    assert not (seen["train"] & seen["test"])
    assert not (seen["val"] & seen["test"])
    assert sorted(i for v in splits.values() for i in v) == list(range(len(entries)))


def test_few_signers_falls_back_to_stratified_with_warning():
    entries = _entries(signers=2, per_signer=30)
    splits, report = split_entries(entries, seed=1)
    assert report["strategy"] == "stratified"
    assert any("indépendant" in w for w in report["warnings"])
    sizes = report["sizes"]
    assert sizes["train"] > sizes["val"] > 0 and sizes["test"] > 0
    for part in ("train", "test"):
        assert {entries[i]["label"] for i in splits[part]} == {"a", "b", "c"}


def test_duplicates_stay_in_the_same_split():
    entries = _entries(signers=1, per_signer=40)
    for i in range(0, 40, 4):
        entries[i + 1]["fingerprint"] = entries[i]["fingerprint"]
        entries[i + 1]["label"] = entries[i]["label"]
    splits, _ = split_entries(entries, seed=3)
    where = {i: k for k, v in splits.items() for i in v}
    for i in range(0, 40, 4):
        assert where[i] == where[i + 1]


def test_custom_ratios_and_predefined_folders():
    entries = _entries(signers=10, per_signer=10)
    _, report = split_entries(entries, {"train": 0.8, "val": 0.1, "test": 0.1}, seed=0)
    assert report["ratios"]["train"] == 0.8
    hinted = [{"label": "a", "split_hint": h} for h in ["train"] * 5 + ["test"] * 2 + ["val"]]
    splits, report = split_entries(hinted)
    assert report["strategy"] == "predefined"
    assert len(splits["train"]) == 5 and len(splits["test"]) == 2 and len(splits["val"]) == 1
