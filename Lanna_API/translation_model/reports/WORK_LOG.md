# Work log

## 2026-08-02

1. Inspected the existing API and AI-engine file inventory.
2. Located `ai_engine/lanna_dict.json` as the available Thai–Tai Tham paired source.
3. Audited 204 records for empties, duplicates, control placeholders, Thai characters in the Lanna target, and presence of Tai Tham Unicode.
4. Copied the source into an isolated raw-data directory without modifying the original.
5. Added `scripts/prepare_dataset.py` with deterministic Unicode normalization, rejection reporting, pair-level splitting, and bidirectional row generation.
6. Generated `train.jsonl`, `validation.jsonl`, `test.jsonl`, `rejected.json`, and `data_report.json`.
7. Added a Google Colab notebook for `google/byt5-small` fine-tuning, validation, test evaluation, metadata capture, model saving, and ZIP export.
8. Added dependency constraints, usage documentation, a model card, and this work log.
9. Validated that the notebook is syntactically valid JSON.
10. Corrected the API mapping for `สวัสดี` to `ᩈ᩠ᩅᩢᩈ᩠ᨯᩦ` using the spelling confirmed by the project owner.
11. Added the confirmed pair to `data/raw/verified_overrides.json`, updated the preparation pipeline and Colab notebook to load it, and regenerated all processed splits.

## Files created

- `README.md`
- `MODEL_CARD.md`
- `requirements-colab.txt`
- `colab_train_byt5.ipynb`
- `scripts/prepare_dataset.py`
- `data/raw/lanna_dict.json`
- `data/raw/verified_overrides.json`
- `data/processed/train.jsonl`
- `data/processed/validation.jsonl`
- `data/processed/test.jsonl`
- `data/processed/rejected.json`
- `data/processed/data_report.json`
- `reports/DATA_REPORT.md`
- `reports/WORK_LOG.md`

## Not yet done

- The ByT5 checkpoint has not yet been downloaded or fine-tuned.
- No GPU training metrics exist yet.
- No expert linguistic review has been completed.
- The model is not connected to the production API or Flutter app.

Those items occur when the notebook is run in a Colab GPU session and the resulting checkpoint is reviewed.

## 2026-08-02 - deterministic Moradok Lanna conversion

1. Confirmed that the web dictionary uses the legacy `LN_TILOK_V6_05.TTF`
   keyboard encoding rather than Unicode Tai Tham.
2. Matched its glyphs against the Unicode `Pali_Tilok.ttf` font and implemented
   `scripts/ln_tilok_to_unicode.py`, including subjoined-consonant handling.
3. Added `scripts/scrape_moradoklanna.py` with resumable page collection,
   provenance, retry handling, bounded concurrency, and rendered-shape checks.
4. Processed all 869 result pages: 34,748 table rows and 17,781 unique
   candidates.
5. Automatically verified 7,216 conversions by shape. The metadata validator
   accepted 7,176 records and quarantined 10,605 for review.
6. Rebuilt the combined pair-level splits: 5,865 train, 733 validation, and 733
   test pairs, producing 11,730 bidirectional training rows.

## 2026-08-02 - external dictionary ingestion

1. Recorded the project owner's confirmation that the two supplied dictionaries may be used for this private model.
2. Downloaded and validated the Google Drive PDF: 672 pages, 9,124,900 bytes, SHA-256 `292b27975da43716c4588e3ee08f9af5ef53983e000e42c95267c7f3075fa6cb`.
3. Sampled 24 pages across the PDF. None contained embedded text, confirming that OCR is required.
4. Inspected representative rendered pages and confirmed a two-column layout containing Lanna script, pronunciation, Thai definitions, and headwords.
5. Inspected the 421-page AnyFlip source. Its searchable layer contains legacy non-Unicode Lanna encoding, so it is not safe as a training target without conversion or OCR review.
6. Added `colab_extract_external_dictionaries.ipynb`, which downloads both sources, renders and crops pages, creates resumable OCR candidates, and sends all candidates to a review queue.
7. Added strict review validation. Only human-approved rows containing real Tai Tham Unicode, pronunciation, meaning, and source provenance can enter training.
8. Updated `prepare_dataset.py` and the ByT5 Colab notebook to include approved external records while preserving pair-level split isolation.
9. Syntax-checked all Python scripts, validated both notebooks as JSON, smoke-tested the approval gate, and rebuilt the original 156-pair dataset without regression.
