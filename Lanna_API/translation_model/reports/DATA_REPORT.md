# Data audit report

Date: 2026-08-02  
Seed: `20260802`

## Source

`D:\PROJECT_LANNA\Lanna_API\ai_engine\lanna_dict.json` was copied to `data/raw/lanna_dict.json`. The original file was not modified.

## Results

| Item | Count |
|---|---:|
| Base raw records | 204 |
| Owner-verified override records | 1 |
| Accepted external records | 7,176 |
| Total records processed | 7,381 |
| Accepted pairs | 7,331 |
| Rejected records | 50 |
| `<ctrl...>` placeholder occurrences | 8 |
| Thai Unicode found in Lanna target | 42 |
| Train pairs | 5,865 |
| Validation pairs | 733 |
| Test pairs | 733 |
| Bidirectional training rows | 11,730 |

One rejected record can have more than one rejection reason, so reason totals may exceed rejected-record totals.

## Leakage prevention

Data is split by a stable `pair_id` before Thai→Lanna and Lanna→Thai rows are created. Therefore a pair and its reversed version cannot be placed in different splits.

## Limitations

- It contains mostly dictionary words, not natural sentence pairs.
- Source terms should be documented before redistributing the dataset or model.
- Automatic Unicode filtering does not prove linguistic correctness.
- The owner-verified `สวัสดี` → `ᩈ᩠ᩅᩢᩈ᩠ᨯᩦ` pair is recorded separately in `data/raw/verified_overrides.json`.
- External records passed automated glyph-shape checks, not expert linguistic review.

## Decision

Suitable for a reproducible proof-of-concept Colab run only. Not sufficient for a production sentence translator.
