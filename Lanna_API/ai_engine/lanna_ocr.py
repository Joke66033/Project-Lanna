"""Experimental single-line Lanna OCR pipeline.

The upstream OCR-Lanna network classifies one cropped component at a time.
This module adds deterministic image preprocessing, connected-component
segmentation, spatial ordering, and confidence reporting around that model.
"""

from __future__ import annotations

import os
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any

import cv2
import numpy as np


MODULE_DIR = Path(__file__).resolve().parent
UPSTREAM_DIR = MODULE_DIR / "third_party" / "OCR-Lanna"
DEFAULT_MODEL_PATH = UPSTREAM_DIR / "Model" / "OCR-lanna.h5"
DEFAULT_TRAIN_DIR = UPSTREAM_DIR / "dataset" / "model" / "train"

# Predict.py is used as the canonical map. Train_model.py contains a duplicate
# P key and an incorrect class count, as documented in OCR_LANNA_AUDIT.md.
LABEL_TO_THAI = {
    "_n": "-น",
    "_m": "-ม",
    "_o": "-อ",
    "K": "ก",
    "KH": "ฃ",
    "C": "ค",
    "NG": "ง",
    "J": "จ",
    "CH": "ฉ",
    "NN": "ณ",
    "D": "ด",
    "T": "ต",
    "N": "น",
    "B": "บ",
    "PA": "ป",
    "PH": "ผ",
    "F": "ฝ",
    "P": "พ",
    "M": "ม",
    "Y": "ย",
    "R": "ร",
    "L": "ล",
    "V": "ว",
    "S": "ส",
    "H": "ห",
    "HL": "หลฯ",
    "OY": "อยฯ",
    "A": "ะ",
    "Aa": "ั",
    "AAA": "า",
    "EI": "ิ",
    "EE": "ี",
    "EU": "ุ",
    "EA": "เ",
    "AI": "ใ",
}


@dataclass(frozen=True)
class BoundingBox:
    x: int
    y: int
    width: int
    height: int


@dataclass(frozen=True)
class CharacterPrediction:
    label: str
    thai: str
    confidence: float
    box: BoundingBox
    position: str


@dataclass(frozen=True)
class LannaOCRResult:
    thai_text: str
    confidence: float
    is_low_confidence: bool
    characters: tuple[CharacterPrediction, ...]
    image_width: int
    image_height: int
    warning: str

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


class LannaOCR:
    """Classify a clean, predominantly single-line Lanna text image."""

    def __init__(
        self,
        model_path: str | os.PathLike[str] = DEFAULT_MODEL_PATH,
        train_dir: str | os.PathLike[str] = DEFAULT_TRAIN_DIR,
        confidence_threshold: float = 0.65,
    ) -> None:
        self.model_path = Path(model_path)
        self.train_dir = Path(train_dir)
        self.confidence_threshold = confidence_threshold
        self._model = None
        self.class_names = self._load_class_names()
        self._validate_assets()

    def _load_class_names(self) -> tuple[str, ...]:
        if not self.train_dir.is_dir():
            raise FileNotFoundError(f"Training class directory not found: {self.train_dir}")
        # Keras flow_from_directory assigns indices in alphanumeric order.
        return tuple(sorted(path.name for path in self.train_dir.iterdir() if path.is_dir()))

    def _validate_assets(self) -> None:
        if not self.model_path.is_file():
            raise FileNotFoundError(f"OCR-Lanna model not found: {self.model_path}")
        missing = [label for label in self.class_names if label not in LABEL_TO_THAI]
        if missing:
            raise ValueError(f"Missing Thai mappings for labels: {', '.join(missing)}")
        if len(self.class_names) != 35:
            raise ValueError(f"Expected 35 OCR classes, found {len(self.class_names)}")

    @property
    def model(self):
        if self._model is None:
            os.environ.setdefault("TF_CPP_MIN_LOG_LEVEL", "2")
            from tensorflow.keras.models import load_model

            self._model = load_model(self.model_path, compile=False)
            if int(self._model.output_shape[-1]) != len(self.class_names):
                raise ValueError(
                    "Model output count does not match the dataset class ordering"
                )
        return self._model

    @staticmethod
    def _read_image(image_or_path: str | os.PathLike[str] | np.ndarray) -> np.ndarray:
        if isinstance(image_or_path, np.ndarray):
            image = image_or_path.copy()
        else:
            # cv2.imread on Windows can fail for Thai/Unicode paths.
            encoded = np.fromfile(str(image_or_path), dtype=np.uint8)
            image = cv2.imdecode(encoded, cv2.IMREAD_UNCHANGED)
        if image is None or image.size == 0:
            raise ValueError("Image could not be read")
        if image.ndim == 2:
            image = cv2.cvtColor(image, cv2.COLOR_GRAY2BGR)
        elif image.shape[2] == 4:
            color = image[:, :, :3].astype(np.float32)
            alpha = image[:, :, 3:4].astype(np.float32) / 255.0
            image = (color * alpha + 255.0 * (1.0 - alpha)).astype(np.uint8)
        return image

    @staticmethod
    def _binarize(image: np.ndarray) -> np.ndarray:
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        if max(gray.shape) > 2200:
            scale = 2200 / max(gray.shape)
            gray = cv2.resize(gray, None, fx=scale, fy=scale, interpolation=cv2.INTER_AREA)
        gray = cv2.GaussianBlur(gray, (3, 3), 0)
        border = np.concatenate((
            gray[0, :],
            gray[-1, :],
            gray[:, 0],
            gray[:, -1],
        ))
        threshold_mode = (
            cv2.THRESH_BINARY_INV
            if float(np.median(border)) >= 128
            else cv2.THRESH_BINARY
        )
        binary = cv2.threshold(
            gray, 0, 255, threshold_mode | cv2.THRESH_OTSU
        )[1]
        # Remove isolated camera noise while retaining small vowel components.
        binary = cv2.morphologyEx(
            binary,
            cv2.MORPH_OPEN,
            cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2, 2)),
        )
        return binary

    @staticmethod
    def _component_boxes(binary: np.ndarray) -> list[BoundingBox]:
        count, _, stats, _ = cv2.connectedComponentsWithStats(binary, connectivity=8)
        image_area = binary.shape[0] * binary.shape[1]
        min_area = max(8, int(image_area * 0.000025))
        max_area = int(image_area * 0.75)
        boxes: list[BoundingBox] = []
        for index in range(1, count):
            x, y, width, height, area = (int(value) for value in stats[index])
            if area < min_area or area > max_area:
                continue
            if width < 2 or height < 2:
                continue
            boxes.append(BoundingBox(x, y, width, height))
        return boxes

    @staticmethod
    def _crop_for_model(binary: np.ndarray, box: BoundingBox) -> np.ndarray:
        crop = binary[
            box.y : box.y + box.height,
            box.x : box.x + box.width,
        ]
        # The upstream model was trained with flow_from_directory resizing each
        # crop directly to 70x70. Preserve that distortion here; adding a square
        # canvas changes the training distribution and collapses accuracy.
        resized = cv2.resize(crop, (70, 70), interpolation=cv2.INTER_LINEAR)
        return cv2.cvtColor(resized, cv2.COLOR_GRAY2RGB).astype(np.float32)

    @staticmethod
    def _position_for_box(box: BoundingBox, baseline_y: float, median_height: float) -> str:
        center_y = box.y + box.height / 2
        if box.height < median_height * 0.72 and center_y < baseline_y - median_height * 0.18:
            return "above"
        if box.height < median_height * 0.72 and center_y > baseline_y + median_height * 0.30:
            return "below"
        return "base"

    @staticmethod
    def _reading_order(
        predictions: list[CharacterPrediction],
    ) -> list[CharacterPrediction]:
        base = sorted(
            (item for item in predictions if item.position == "base"),
            key=lambda item: item.box.x,
        )
        marks = [item for item in predictions if item.position != "base"]
        if not base:
            return sorted(predictions, key=lambda item: (item.box.x, item.box.y))

        groups: dict[int, list[CharacterPrediction]] = {index: [] for index in range(len(base))}
        for mark in marks:
            mark_center = mark.box.x + mark.box.width / 2
            owner = min(
                range(len(base)),
                key=lambda index: abs(
                    mark_center - (base[index].box.x + base[index].box.width / 2)
                ),
            )
            groups[owner].append(mark)

        ordered: list[CharacterPrediction] = []
        for index, character in enumerate(base):
            above = sorted(
                (item for item in groups[index] if item.position == "above"),
                key=lambda item: (item.box.y, item.box.x),
            )
            below = sorted(
                (item for item in groups[index] if item.position == "below"),
                key=lambda item: (item.box.y, item.box.x),
            )
            # Thai reading order stores combining vowels after the base.
            ordered.append(character)
            ordered.extend(above)
            ordered.extend(below)
        return ordered

    @staticmethod
    def _clean_joined_text(predictions: list[CharacterPrediction]) -> str:
        text = "".join(item.thai for item in predictions)
        return text.replace("-", "").replace("ฯ", "")

    def recognize(
        self,
        image_or_path: str | os.PathLike[str] | np.ndarray,
    ) -> LannaOCRResult:
        image = self._read_image(image_or_path)
        binary = self._binarize(image)
        boxes = self._component_boxes(binary)
        if not boxes:
            raise ValueError("No Lanna character components were detected")

        heights = np.array([box.height for box in boxes], dtype=np.float32)
        median_height = float(np.median(heights))
        large_boxes = [box for box in boxes if box.height >= median_height]
        baseline_y = float(
            np.median([box.y + box.height / 2 for box in large_boxes or boxes])
        )

        batch = np.stack([self._crop_for_model(binary, box) for box in boxes])
        probabilities = np.asarray(self.model.predict(batch, verbose=0))
        predictions: list[CharacterPrediction] = []
        for box, scores in zip(boxes, probabilities):
            class_index = int(np.argmax(scores))
            label = self.class_names[class_index]
            predictions.append(
                CharacterPrediction(
                    label=label,
                    thai=LABEL_TO_THAI[label],
                    confidence=float(scores[class_index]),
                    box=box,
                    position=self._position_for_box(box, baseline_y, median_height),
                )
            )

        ordered = self._reading_order(predictions)
        confidences = [item.confidence for item in ordered]
        mean_confidence = float(np.mean(confidences)) if confidences else 0.0
        is_low_confidence = (
            mean_confidence < self.confidence_threshold
            or any(value < self.confidence_threshold for value in confidences)
        )
        warning = (
            "ผล OCR ล้านนาอยู่ในขั้นทดลอง โปรดตรวจสอบกับภาพต้นฉบับ"
            if is_low_confidence
            else "ผล OCR ล้านนาเป็นผลจากโมเดลทดลอง ควรตรวจทานก่อนใช้งาน"
        )
        return LannaOCRResult(
            thai_text=self._clean_joined_text(ordered),
            confidence=mean_confidence,
            is_low_confidence=is_low_confidence,
            characters=tuple(ordered),
            image_width=int(binary.shape[1]),
            image_height=int(binary.shape[0]),
            warning=warning,
        )
