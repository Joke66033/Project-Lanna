# External dictionary ingestion

## Confirmed sources

The project owner confirmed on 2026-08-02 that both supplied sources may be used for the private model. Source URLs, titles, page counts, and ingestion state are stored in `data/raw/external/source_manifest.json`.

## Why the books cannot be sent directly to ByT5

The 672-page Google Drive PDF is image-only. The AnyFlip book exposes a legacy Lanna text layer whose code points are mostly Thai characters and punctuation rather than Unicode Tai Tham. Training directly on either raw representation would teach the wrong target spelling.

Every candidate entry must therefore pass through this sequence:

1. OCR or legacy-font conversion produces a candidate record.
2. The candidate is stored in `review_queue.jsonl` with its exact source page.
3. A reviewer compares the candidate with the page image and changes `review_status` to `approved` only after correcting all four fields.
4. `validate_review_queue.py` rejects missing fields, Thai code points in the Lanna target, non-Tai-Tham targets, duplicates, and missing provenance.
5. Only `approved_records.jsonl` is allowed into `prepare_dataset.py`.

## Required JSONL schema

```json
{"thai":"สวัสดี","lanna":"ᩈ᩠ᩅᩢᩈ᩠ᨯᩦ","pronunciation":"สะ-วัด-ดี","meaning":"คำทักทาย","source_id":"...","source_page":123,"review_status":"approved"}
```

## Validate reviewed records

```powershell
python scripts/validate_review_queue.py `
  --input data/raw/external/review_queue.jsonl `
  --accepted data/raw/external/approved_records.jsonl `
  --rejected data/raw/external/rejected_records.jsonl `
  --report reports/external_validation_report.json
```

## Rebuild the training splits

```powershell
python scripts/prepare_dataset.py `
  --input data/raw/lanna_dict.json `
  --verified-overrides data/raw/verified_overrides.json `
  --external-input data/raw/external/approved_records.jsonl `
  --output-dir data/processed
```

The empty approved file is intentional. It prevents unreviewed OCR output from silently contaminating the model.
