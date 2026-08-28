"""Render scanned dictionary pages and OCR each printed column separately."""

from __future__ import annotations

import argparse
from pathlib import Path
import subprocess
import tempfile

from PIL import Image, ImageEnhance, ImageOps


def run_checked(command: list[str]) -> None:
    subprocess.run(command, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--pdf", required=True, type=Path)
    parser.add_argument("--output-dir", required=True, type=Path)
    parser.add_argument("--page-from", required=True, type=int)
    parser.add_argument("--page-to", required=True, type=int)
    parser.add_argument("--pdftoppm", required=True, type=Path)
    parser.add_argument("--tesseract", required=True, type=Path)
    args = parser.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory(prefix="lanna-column-ocr-") as temp_dir:
        temp = Path(temp_dir)
        for page in range(args.page_from, args.page_to + 1):
            image_root = temp / f"page-{page:03d}"
            run_checked([
                str(args.pdftoppm), "-f", str(page), "-l", str(page),
                "-r", "300", "-gray", "-png", "-singlefile",
                str(args.pdf), str(image_root),
            ])
            with Image.open(image_root.with_suffix(".png")) as source:
                gray = ImageOps.grayscale(source)
                gray = ImageEnhance.Contrast(gray).enhance(1.35)
                width, height = gray.size
                top, bottom = int(height * 0.045), int(height * 0.965)
                crops = [
                    gray.crop((int(width * 0.055), top, int(width * 0.505), bottom)),
                    gray.crop((int(width * 0.495), top, int(width * 0.945), bottom)),
                ]
                texts = []
                for side, crop in zip(("left", "right"), crops):
                    crop_path = temp / f"page-{page:03d}-{side}.png"
                    output_root = temp / f"page-{page:03d}-{side}"
                    crop.save(crop_path)
                    run_checked([
                        str(args.tesseract), str(crop_path), str(output_root),
                        "-l", "tha+eng", "--psm", "6", "preserve_interword_spaces=1",
                    ])
                    texts.append(output_root.with_suffix(".txt").read_text(encoding="utf-8", errors="replace"))
            (args.output_dir / f"page-{page:03d}.txt").write_text(
                "\n".join(texts), encoding="utf-8"
            )
            print(f"OCR page {page}/{args.page_to}", flush=True)


if __name__ == "__main__":
    main()
