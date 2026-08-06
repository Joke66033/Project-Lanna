# OCR-Lanna technical audit

Source: `https://github.com/PrABpY/OCR-Lanna`

Inspected commit: `18ff7febe960903371b621705054a0f3ce0dbd5e`

## Assets

- Saved model: `Model/OCR-lanna.h5`
- Model input: `70 x 70 x 3`
- Model output: `35` character classes
- Model parameters: `1,736,547`
- Training images: `2,891`
- Test images: `462`
- Training and test directory classes: `35`

## Findings that must be handled by the integration

1. `Train_model.py` sets `nclass = 36`, although the dataset and saved model
   contain 35 classes. The integration must derive class count from the saved
   model/dataset rather than copy this constant.
2. The `encode` mapping in `Train_model.py` declares `P` twice. Python keeps
   only the latter value. `Predict.py` uses separate `PA` and `P` keys and is
   the safer basis for the label map.
3. The dataset is highly imbalanced. Examples include class `N` with one
   training image and classes `A` and `HL` with three images each. Overall
   accuracy can therefore hide very weak per-class performance.
4. The supplied model is a single-character CNN. It is not an end-to-end line
   OCR model. Text images must first be segmented into character components,
   ordered spatially, and recombined.
5. The repository contains no license file and its README states that no
   license information is supplied. Obtain permission from the owner before
   distributing the model, dataset, or derived application publicly.

## Integration policy

- Keep this feature labelled experimental until per-class and full-image tests
  are reviewed.
- Return confidence for every detected character.
- Do not silently return low-confidence text as a certain translation.
- Preserve the original image and bounding boxes during evaluation so errors
  can be audited.

