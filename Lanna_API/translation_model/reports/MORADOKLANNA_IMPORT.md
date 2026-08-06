# Moradok Lanna import report

- Source: `https://moradoklanna.com/dict/`
- Pages processed: 869
- Table rows observed: 34,748
- Unique candidates written: 17,781
- Shape-verified conversions: 7,216
- Records accepted after metadata and duplicate validation: 7,176
- Records retained for review: 10,605
- Conversion method: `ln_tilok_font_map_v1`
- Visual acceptance threshold: 0.86

The source website displays Lanna text through a legacy font encoding. The
pipeline maps the legacy code points to Unicode Tai Tham, renders both forms in
their respective fonts, and compares their silhouettes. A row is eligible only
when the converter reports no unknown code point and the shape score reaches the
threshold. Pronunciation, meaning, Thai source, Tai Tham output, and provenance
are validated again before dataset preparation.

The review queue is intentionally retained. It must not be merged into training
without correcting the conversion and checking it against the source.
