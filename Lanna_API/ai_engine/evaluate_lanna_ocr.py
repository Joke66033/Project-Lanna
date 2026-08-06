"""Evaluate the upstream OCR-Lanna model without opening GUI windows."""

from __future__ import annotations

import argparse
import hashlib
import json
from collections import defaultdict
from pathlib import Path

import cv2
import numpy as np
from sklearn.metrics import confusion_matrix

from lanna_ocr import LABEL_TO_THAI, LannaOCR


IMAGE_SUFFIXES = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}


def image_files(root: Path) -> list[tuple[str, Path]]:
    files: list[tuple[str, Path]] = []
    for class_dir in sorted(path for path in root.iterdir() if path.is_dir()):
        for path in sorted(class_dir.iterdir()):
            if path.is_file() and path.suffix.lower() in IMAGE_SUFFIXES:
                files.append((class_dir.name, path))
    return files


def raw_model_image(path: Path) -> np.ndarray:
    image = cv2.imdecode(np.fromfile(str(path), dtype=np.uint8), cv2.IMREAD_COLOR)
    if image is None:
        raise ValueError(f"Unreadable image: {path}")
    image = cv2.resize(image, (70, 70), interpolation=cv2.INTER_LINEAR)
    return cv2.cvtColor(image, cv2.COLOR_BGR2RGB).astype(np.float32)


def deployed_model_array(ocr: LannaOCR, image: np.ndarray) -> np.ndarray:
    binary = ocr._binarize(image)
    boxes = ocr._component_boxes(binary)
    if not boxes:
        return np.zeros((70, 70, 3), dtype=np.float32)
    # Character samples can contain disconnected marks. Use their union so the
    # deployed preprocessing does not discard a vowel or tone component.
    x1 = min(box.x for box in boxes)
    y1 = min(box.y for box in boxes)
    x2 = max(box.x + box.width for box in boxes)
    y2 = max(box.y + box.height for box in boxes)
    from lanna_ocr import BoundingBox

    return ocr._crop_for_model(binary, BoundingBox(x1, y1, x2 - x1, y2 - y1))


def deployed_model_image(ocr: LannaOCR, path: Path) -> np.ndarray:
    return deployed_model_array(ocr, ocr._read_image(path))


def transformed_image(path: Path, variant: str) -> np.ndarray:
    image = cv2.imdecode(np.fromfile(str(path), dtype=np.uint8), cv2.IMREAD_COLOR)
    if image is None:
        raise ValueError(f"Unreadable image: {path}")
    height, width = image.shape[:2]
    if variant in {"rotate_left", "rotate_right"}:
        angle = -5 if variant == "rotate_left" else 5
        matrix = cv2.getRotationMatrix2D((width / 2, height / 2), angle, 1.0)
        border_value = tuple(int(value) for value in np.median(
            np.concatenate((image[0], image[-1], image[:, 0], image[:, -1])),
            axis=0,
        ))
        return cv2.warpAffine(
            image,
            matrix,
            (width, height),
            flags=cv2.INTER_LINEAR,
            borderMode=cv2.BORDER_CONSTANT,
            borderValue=border_value,
        )
    if variant == "blur":
        return cv2.GaussianBlur(image, (5, 5), 1.2)
    if variant == "low_contrast":
        return cv2.convertScaleAbs(image, alpha=0.55, beta=55)
    if variant == "noise":
        seed = int(hashlib.sha256(path.as_posix().encode()).hexdigest()[:8], 16)
        rng = np.random.default_rng(seed)
        noise = rng.normal(0, 12, image.shape).astype(np.float32)
        return np.clip(image.astype(np.float32) + noise, 0, 255).astype(np.uint8)
    raise ValueError(f"Unknown robustness variant: {variant}")


def duplicate_audit(train_files: list[tuple[str, Path]], test_files: list[tuple[str, Path]]):
    train_hashes: dict[str, list[tuple[str, str]]] = defaultdict(list)
    for label, path in train_files:
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        train_hashes[digest].append((label, str(path)))

    duplicates = []
    for label, path in test_files:
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        for train_label, train_path in train_hashes.get(digest, []):
            duplicates.append({
                "test_label": label,
                "test_path": str(path),
                "train_label": train_label,
                "train_path": train_path,
            })
    return duplicates


def supplemental_labeled_files(
    ocr: LannaOCR,
    known_model_hashes: set[str],
) -> tuple[list[tuple[int, Path]], dict]:
    dataset_root = ocr.train_dir.parent.parent
    candidates = [
        path
        for path in dataset_root.iterdir()
        if path.is_dir() and path.name != "model"
    ]
    if not candidates:
        return [], {"reason": "No supplemental labeled directory found"}
    source_root = max(
        candidates,
        key=lambda path: sum(1 for child in path.iterdir() if child.is_dir()),
    )

    thai_to_labels: dict[str, list[str]] = defaultdict(list)
    for label, thai in LABEL_TO_THAI.items():
        thai_to_labels[thai.replace("-", "").replace("ฯ", "")].append(label)

    usable: list[tuple[int, Path]] = []
    skipped_ambiguous = 0
    skipped_duplicate = 0
    for folder in source_root.iterdir():
        if not folder.is_dir():
            continue
        labels = thai_to_labels.get(folder.name, [])
        if len(labels) != 1:
            skipped_ambiguous += sum(
                1 for path in folder.iterdir() if path.is_file()
            )
            continue
        class_index = ocr.class_names.index(labels[0])
        for path in folder.iterdir():
            if not path.is_file() or path.suffix.lower() not in IMAGE_SUFFIXES:
                continue
            if hashlib.sha256(path.read_bytes()).hexdigest() in known_model_hashes:
                skipped_duplicate += 1
                continue
            usable.append((class_index, path))
    return usable, {
        "source_root": str(source_root),
        "usable_count": len(usable),
        "skipped_ambiguous_or_unsupported": skipped_ambiguous,
        "skipped_exact_duplicate": skipped_duplicate,
        "provenance_warning": (
            "These images come from the same upstream repository and may be "
            "source material for the trained crops; treat this as supplemental, "
            "not a fully independent benchmark."
        ),
    }


def metrics(
    y_true: np.ndarray,
    probabilities: np.ndarray,
    class_names: tuple[str, ...],
    confidence_threshold: float,
) -> dict:
    y_pred = np.argmax(probabilities, axis=1)
    confidence = np.max(probabilities, axis=1)
    top3 = np.argsort(probabilities, axis=1)[:, -3:]
    matrix = confusion_matrix(
        y_true,
        y_pred,
        labels=np.arange(len(class_names)),
    )

    per_class = {}
    recalls = []
    for index, label in enumerate(class_names):
        support = int(np.sum(y_true == index))
        correct = int(matrix[index, index])
        recall = correct / support if support else 0.0
        recalls.append(recall)
        class_mask = y_true == index
        per_class[label] = {
            "support": support,
            "correct": correct,
            "accuracy": round(recall, 6),
            "mean_confidence": round(float(np.mean(confidence[class_mask])), 6)
            if support
            else 0.0,
        }

    accepted = confidence >= confidence_threshold
    accepted_count = int(np.sum(accepted))
    return {
        "sample_count": int(len(y_true)),
        "accuracy": round(float(np.mean(y_pred == y_true)), 6),
        "macro_accuracy": round(float(np.mean(recalls)), 6),
        "top3_accuracy": round(
            float(np.mean([truth in choices for truth, choices in zip(y_true, top3)])),
            6,
        ),
        "mean_confidence": round(float(np.mean(confidence)), 6),
        "threshold": confidence_threshold,
        "accepted_count": accepted_count,
        "accepted_coverage": round(accepted_count / len(y_true), 6),
        "accepted_accuracy": round(
            float(np.mean(y_pred[accepted] == y_true[accepted])),
            6,
        )
        if accepted_count
        else 0.0,
        "per_class": per_class,
        "confusion_matrix": matrix.tolist(),
    }


def evaluate(output_path: Path) -> dict:
    ocr = LannaOCR()
    train_files = image_files(ocr.train_dir)
    test_dir = ocr.train_dir.parent / "test"
    test_files = image_files(test_dir)
    label_to_index = {label: index for index, label in enumerate(ocr.class_names)}
    y_true = np.array([label_to_index[label] for label, _ in test_files])
    known_model_hashes = {
        hashlib.sha256(path.read_bytes()).hexdigest()
        for _, path in train_files + test_files
    }

    raw_batch = np.stack([raw_model_image(path) for _, path in test_files])
    deployed_batch = np.stack([
        deployed_model_image(ocr, path) for _, path in test_files
    ])
    raw_probabilities = np.asarray(ocr.model.predict(raw_batch, batch_size=64, verbose=0))
    deployed_probabilities = np.asarray(
        ocr.model.predict(deployed_batch, batch_size=64, verbose=0)
    )
    robustness = {}
    for variant in ("rotate_left", "rotate_right", "blur", "low_contrast", "noise"):
        batch = np.stack([
            deployed_model_array(ocr, transformed_image(path, variant))
            for _, path in test_files
        ])
        probabilities = np.asarray(
            ocr.model.predict(batch, batch_size=64, verbose=0)
        )
        robustness[variant] = metrics(
            y_true,
            probabilities,
            ocr.class_names,
            ocr.confidence_threshold,
        )
    supplemental_files, supplemental_info = supplemental_labeled_files(
        ocr,
        known_model_hashes,
    )
    if supplemental_files:
        supplemental_true = np.array([label for label, _ in supplemental_files])
        supplemental_batch = np.stack([
            deployed_model_image(ocr, path) for _, path in supplemental_files
        ])
        supplemental_probabilities = np.asarray(
            ocr.model.predict(supplemental_batch, batch_size=64, verbose=0)
        )
        supplemental_info["metrics"] = metrics(
            supplemental_true,
            supplemental_probabilities,
            ocr.class_names,
            ocr.confidence_threshold,
        )

    report = {
        "model_path": str(ocr.model_path),
        "class_names": list(ocr.class_names),
        "train_count": len(train_files),
        "test_count": len(test_files),
        "exact_train_test_duplicates": duplicate_audit(train_files, test_files),
        "raw_prepared_characters": metrics(
            y_true,
            raw_probabilities,
            ocr.class_names,
            ocr.confidence_threshold,
        ),
        "deployed_binary_preprocessing": metrics(
            y_true,
            deployed_probabilities,
            ocr.class_names,
            ocr.confidence_threshold,
        ),
        "robustness": robustness,
        "supplemental_labeled_source_images": supplemental_info,
    }
    output_path.write_text(
        json.dumps(report, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    return report


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--output",
        type=Path,
        default=Path(__file__).resolve().parent / "lanna_ocr_evaluation.json",
    )
    args = parser.parse_args()
    report = evaluate(args.output)
    summary = {
        "output": str(args.output),
        "train_count": report["train_count"],
        "test_count": report["test_count"],
        "exact_duplicate_count": len(report["exact_train_test_duplicates"]),
        "raw_accuracy": report["raw_prepared_characters"]["accuracy"],
        "raw_macro_accuracy": report["raw_prepared_characters"]["macro_accuracy"],
        "deployed_accuracy": report["deployed_binary_preprocessing"]["accuracy"],
        "deployed_macro_accuracy": report["deployed_binary_preprocessing"]["macro_accuracy"],
        "robustness_accuracy": {
            name: values["accuracy"] for name, values in report["robustness"].items()
        },
        "supplemental_accuracy": report["supplemental_labeled_source_images"]
        .get("metrics", {})
        .get("accuracy"),
    }
    print(json.dumps(summary, ensure_ascii=True))


if __name__ == "__main__":
    main()
