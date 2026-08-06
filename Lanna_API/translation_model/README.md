# Lanna translation model — reproducible Colab pipeline

This directory contains a proof-of-concept fine-tuning pipeline for Thai ↔ Tai Tham (Lanna).

## Current data status

The raw source is `data/raw/lanna_dict.json`. Data preparation rejects empty rows, duplicate pairs, `<ctrl...>` placeholders, targets containing Thai Unicode, and targets without Tai Tham Unicode. The script creates bidirectional rows only after splitting by pair, preventing the reverse direction of a test pair from leaking into training.

The Moradok Lanna dictionary was also ingested with a deterministic LN Tilok
legacy-font to Unicode Tai Tham converter. Of 17,781 unique candidates, 7,176
passed the strict Unicode, provenance, pronunciation, meaning, and rendered-shape
checks. The other 10,605 remain in a separate review queue and are not used for
training. The combined prepared dataset contains 7,331 accepted word pairs:
5,865 train, 733 validation, and 733 locked test pairs (11,730 bidirectional
training rows).

## Run locally for the data audit

```powershell
python scripts/prepare_dataset.py --input data/raw/lanna_dict.json --output-dir data/processed
```

## Run training in Google Colab

1. Upload the entire `translation_model` directory to Google Drive.
2. Open `colab_train_byt5.ipynb` in Colab.
3. Select a GPU runtime.
4. Change `PROJECT_DIR` in the notebook if your Drive path differs.
5. Run every cell in order.
6. Download `lanna-byt5-poc.zip` and the generated reports.

## External dictionary processing

The checked Moradok Lanna rows are already stored in
`data/raw/external/approved_records.jsonl`. The image-only Google Drive and
AnyFlip sources still require manual review through
`colab_extract_external_dictionaries.ipynb`; OCR output from those sources is
never added automatically.

The source manifest and the reason for the review gate are documented in `reports/EXTERNAL_DATA_GUIDE.md`.

## Important limitation

The current source mostly contains isolated dictionary entries. A trained checkpoint can demonstrate the pipeline, but it must not be described as a production sentence translator. Add expert-reviewed sentence pairs and keep a locked test set before production use.
