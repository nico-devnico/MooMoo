from pathlib import Path

from PIL import Image

from moomoo_ml.datasets.analyzer import analyze_dataset, samples_for_training
from moomoo_ml.datasets.discovery import discover_samples


def _image(path: Path, color: tuple[int, int, int], size=(32, 24)) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.new("RGB", size, color).save(path)


def _gif(path: Path, frames: int = 6, duration_ms: int = 50) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    images = [Image.new("RGB", (20, 20), (i * 30 % 255, 0, 0)) for i in range(frames)]
    images[0].save(path, save_all=True, append_images=images[1:], duration=duration_ms, loop=0)


def _structured(root: Path) -> None:
    # label/file layout with signer ids in the names, one corrupt file and one exact duplicate.
    for label, base in (("bonjour", 10), ("merci", 90), ("oui", 170)):
        for s in range(3):
            _image(root / label / f"signer{s}_{label}.png", (base + s, 40, 40))
    _gif(root / "bonjour" / "signer4_anim.gif")
    (root / "merci" / "broken.png").write_bytes(b"not an image")
    _image(root / "oui" / "signer9_copy.png", (170, 40, 40))  # same pixels as signer0_oui.png
    (root / "README.txt").write_text("notes")


def test_analyzer_reports_real_structure(tmp_path):
    _structured(tmp_path)
    report = analyze_dataset(tmp_path, is_structured=True, is_labeled=True,
                             label_mapping=None, media_format="auto")
    assert report["files_total"] == 12
    assert report["other_files"] == 1
    assert report["extensions"] == {".png": 11, ".gif": 1}
    assert report["classes"] == {"bonjour": 4, "oui": 4, "merci": 3}
    assert report["invalid_count"] == 1 and report["invalid_paths"] == ["merci/broken.png"]
    assert report["duplicate_groups"] == 1
    assert report["signers_count"] == 5
    assert report["media"]["fps"]["mean"] == 20.0
    assert report["media"]["duration_s"]["mean"] == 0.3
    assert report["trainable"] is True
    assert any("corrompu" in w for w in report["warnings"])
    assert any("doublon" in w for w in report["warnings"])


def test_unlabeled_dataset_never_invents_labels(tmp_path):
    _structured(tmp_path)
    report = analyze_dataset(tmp_path, is_structured=True, is_labeled=False,
                             label_mapping=None, media_format="auto")
    assert report["classes_count"] == 0
    assert report["samples_labeled"] == 0
    assert report["trainable"] is False
    assert any("label_mapping" in r for r in report["recommendations"])


def test_label_mapping_assigns_labels_by_longest_prefix(tmp_path):
    _image(tmp_path / "clips" / "a" / "x1.png", (1, 2, 3))
    _image(tmp_path / "clips" / "a" / "special.png", (4, 5, 6))
    _image(tmp_path / "clips" / "b" / "y1.png", (7, 8, 9))
    mapping = {"clips/a": "maison", "clips/a/special.png": "chat", "clips/b": "chien"}
    samples = discover_samples(tmp_path, is_structured=False, is_labeled=False, label_mapping=mapping)
    labels = {s.rel: s.label for s in samples}
    assert labels == {"clips/a/special.png": "chat", "clips/a/x1.png": "maison", "clips/b/y1.png": "chien"}


def test_metadata_csv_and_frame_folders(tmp_path):
    for i in range(3):
        _image(tmp_path / "seq1" / f"{i:03}.png", (i, i, i))
    _image(tmp_path / "solo.png", (9, 9, 9))
    (tmp_path / "labels.csv").write_text(
        "path;label;signer;split\nseq1;au revoir;P1;train\nsolo.png;oui;P2;test\n", encoding="utf-8"
    )
    samples = {s.rel: s for s in discover_samples(tmp_path)}
    assert samples["seq1"].kind == "frames" and len(samples["seq1"].files) == 3
    assert samples["seq1"].label == "au revoir" and samples["seq1"].signer == "P1"
    assert samples["solo.png"].split_hint == "test"


def test_samples_for_training_excludes_invalid_files(tmp_path):
    _structured(tmp_path)
    report = analyze_dataset(tmp_path, is_structured=True, is_labeled=True,
                             label_mapping=None, media_format="auto")
    samples = samples_for_training(tmp_path, {"analysis": report})
    assert all(s.rel != "merci/broken.png" for s in samples)
    assert len(samples) == report["samples_labeled"]
