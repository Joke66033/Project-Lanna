# Model card: lanna-byt5-poc

## External dictionary policy

The Moradok Lanna source uses the legacy LN Tilok font encoding. Its entries are
converted with a deterministic glyph mapping and admitted only when the rendered
legacy and Unicode Tai Tham forms pass a strict shape comparison and all required
metadata is present. OCR candidates from image-only sources are never trusted
automatically and still require human review.

## Intended use

Proof-of-concept translation between Thai text and Tai Tham Unicode using a fine-tuned `google/byt5-small` sequence-to-sequence checkpoint.

## Not intended for

- Unreviewed production translation
- Legal, medical, religious, or historical interpretation
- Claims of fluent sentence translation from the current word-level dataset

## Training data

7,331 accepted word pairs after validation and deduplication. Pair-level splits
contain 5,865 train, 733 validation, and 733 test pairs. Both translation
directions are generated after splitting, producing 11,730 training rows. Exact
counts and rejection reasons are in `data/processed/data_report.json` and
`reports/moradoklanna_validation_report.json`.

## Known risks

- Dictionary-sized but still limited dataset
- Mostly isolated words rather than natural sentences
- Potential dialect and spelling variation
- AI may hallucinate plausible-looking Tai Tham text
- Automatic metrics do not replace review by a Lanna-language expert

## Reproducibility

The notebook records the base model, seed, package versions, training arguments, dataset report, metrics, and output checkpoint.
