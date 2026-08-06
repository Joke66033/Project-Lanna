# Lanna OCR evaluation

Evaluation artifact: `lanna_ocr_evaluation.json`

## Decision

Do not present the current model as production-ready OCR. Keep the endpoint
experimental and do not connect it to the main camera UI yet.

## Results

| Evaluation set | Samples | Accuracy | Macro accuracy | Notes |
|---|---:|---:|---:|---|
| Upstream test images, raw resize | 462 | 98.48% | 97.45% | Invalid as an independent benchmark: every test file is an exact duplicate of a training file. |
| Upstream test images, deployed preprocessing | 462 | 95.02% | 90.92% | Also affected by the 100% train/test duplication. |
| Supplemental labelled source images | 202 | 72.28% | 34.96% | Exact duplicates removed, but images are still from the same upstream repository. |

Top-3 accuracy on the supplemental set is 87.13%.

With a confidence threshold of `0.65`, the model accepts 54.95% of the
supplemental images and is correct on 86.49% of those accepted images. This is
not sufficiently reliable for silent automatic translation.

## Robustness checks

The following figures use transformed versions of the duplicated upstream test
images. They measure preprocessing stability, not generalization to new
handwriting.

| Transformation | Accuracy |
|---|---:|
| Rotate -5 degrees | 91.77% |
| Rotate +5 degrees | 90.91% |
| Gaussian blur | 93.29% |
| Lower contrast | 95.02% |
| Added noise | 95.02% |

## Weak or unreliable classes

On the supplemental labelled images, classes `CH`, `NN`, `_o`, and `R` had
zero correct predictions. Class `C` achieved 13.04%. Several of these classes
have very few examples, so per-class results are unstable as well as weak.

## Required before UI integration

1. Obtain a genuinely independent labelled set captured from phones, including
   printed text and multiple handwriting styles.
2. Split data by source/writer before training so images from the same source
   cannot appear in both training and test sets.
3. Add or rebalance weak classes and retrain the classifier.
4. Evaluate character accuracy, full-word accuracy, and segmentation recall.
5. Only enable automatic output above an agreed threshold; show bounding boxes
   and require confirmation for low-confidence characters.

## User-provided field signs

Seven additional temple-sign photos were added as a field regression set. Two
photos show the same Wat Pa Darapirom sign, so the set contains six independent
sign groups. The Tai Tham line was cropped by ratio for each image.

- Accepted at confidence threshold `0.65`: `0/7`
- Mean character confidence across the seven crops: `12.28%`
- Best crop mean confidence: `24.68%`
- Worst crop mean confidence: `3.62%`

This confirms that the upstream classifier does not generalize to real outdoor
signs. The images remain outside training and should be rerun after synthetic
augmentation/retraining.

## Curated mixed real-world samples

An additional set was curated into 22 crops:

- 17 word images with visible Thai labels
- 1 Thai-only negative image
- 1 context-only temple sign
- 3 unlabeled/transparent Lanna samples

Current baseline:

- Exact full-word matches: `0/17`
- Labelled words accepted at threshold `0.65`: `0/17`
- Mean confidence on labelled words: `32.74%`
- Thai-only negative images correctly rejected: `1/1`

PNG alpha compositing is now supported so transparent Lanna graphics are
evaluated on a white background rather than being decoded as a black image.
