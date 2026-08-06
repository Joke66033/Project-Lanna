import argparse
import hashlib
import json
from pathlib import Path

from pypdf import PdfReader


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def audit_pdf(path: Path, sample_pages: int = 24) -> dict:
    reader = PdfReader(path)
    page_count = len(reader.pages)
    if page_count == 0:
        sampled_indexes = []
    elif page_count <= sample_pages:
        sampled_indexes = list(range(page_count))
    else:
        sampled_indexes = sorted(
            {round(index * (page_count - 1) / (sample_pages - 1)) for index in range(sample_pages)}
        )

    samples = []
    pages_with_text = 0
    for index in sampled_indexes:
        text = (reader.pages[index].extract_text() or "").strip()
        if text:
            pages_with_text += 1
        samples.append({"page": index + 1, "embedded_text_characters": len(text)})

    return {
        "path": str(path),
        "bytes": path.stat().st_size,
        "sha256": sha256(path),
        "page_count": page_count,
        "sampled_pages": samples,
        "sampled_pages_with_embedded_text": pages_with_text,
        "image_only_likely": bool(samples) and pages_with_text == 0,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--pdf", action="append", default=[])
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    report = {"pdf_files": [audit_pdf(Path(value)) for value in args.pdf]}
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
