# Image Encryption Algorithm Using Chaotic Systems

Bachelor's thesis project — Politehnica University of Bucharest, Faculty of Electronics, Telecommunications and Information Technology (ETTI), 2026.

Supervisor: Conf. dr. ing. Mircea Răducanu

## Overview

Implementation, extension, and evaluation of a hybrid image encryption algorithm based on three chaotic maps working in sequence:

1. **Bogdanov Map** — pixel position scrambling (confusion stage)
2. **Logistic Map** — dynamic encryption key generation
3. **Tent Map** — pixel intensity modification via XOR operations (diffusion stage)

The algorithm follows Shannon's confusion–diffusion principles. Encryption keys are derived from the sum of the original image's pixel values, making each key image-dependent.

Key contribution over the reference algorithm: reduction of diffusion rounds from N = 50 to N = 2, validated through NPCR/UACI saturation analysis — achieving near-identical security with drastically lower execution time.

## Results

| Metric | Value |
|---|---|
| Entropy (encrypted) | 7.9969 – 7.9991 bits (ideal: 8.0) |
| NPCR | 99.59% (ideal: 99.6094%) |
| UACI | ~33.46% (ideal: 33.4635%) |
| Spatial correlation (encrypted) | < 0.044 (absolute value) |
| Encryption time – grayscale | **13.68 ms** |
| Encryption time – color RGB | **29.51 ms** |
| PSNR at decryption | ∞ (perfect pixel-by-pixel reconstruction) |

Encryption speed is **48–88× faster** than comparable algorithms in the literature.

## File Structure

```
.
├── encrypt_image_full.m        # Core encryption function (Bogdanov + Logistic + Tent)
├── decrypt_image_full.m        # Core decryption function (inverse pipeline)
├── bogdanov_scramble.m         # Bogdanov map — pixel position permutation
├── criptare_grayscale_1.m      # Full test script for grayscale images
├── criptare_rgb_2.m            # Full test script for RGB color images
└── grafic_corelatie_universal.m # Adjacent pixel correlation analysis and plots
```

## Algorithm Pipeline

```
Original Image
      │
      ▼
[1] Bogdanov Map — pixel scrambling (confusion)
      │   Vectorized coordinate permutation, bijective for square images
      ▼
[2] Logistic Map — key generation
      │   Seeds derived from sum of original pixel values
      │   Transient regime discarded (first 100 iterations)
      ▼
[3] Tent Map — XOR diffusion (N=2 rounds)
      │   Chaotic sequence → uint8 key matrix → bitxor with image
      ▼
Encrypted Image
```

Decryption runs the pipeline in reverse: XOR diffusion (N rounds, reverse order) → inverse Bogdanov permutation.

## Requirements

- MATLAB R2021a or later
- Image Processing Toolbox
- Test images: `peppers.png`, `cameraman.tif`, `football.jpg`, `saturn.png`, `autumn.tif` (included in MATLAB's standard image set)

## Running

**Grayscale encryption:**
```matlab
% Open criptare_grayscale_1.m
% Set img_file to your target image (line 12)
% Run the script — outputs metrics + figure
```

**RGB encryption:**
```matlab
% Open criptare_rgb_2.m
% Set img_file to your target image (line 12)
% Run the script — outputs per-channel metrics + figure
```

**Standalone encryption/decryption:**
```matlab
img = imread('peppers.png');
img = im2uint8(imresize(img, [256 256]));

enc = encrypt_image_full(img);
dec = decrypt_image_full(enc, sum(double(img(:))));
```

**Correlation analysis:**
```matlab
% Open grafic_corelatie_universal.m
% Set img_file and mode ('gray', 'R', 'G', 'B')
% Outputs correlation coefficients + 300 DPI figure
```

## Security Metrics Explained

| Metric | What it measures | Good value |
|---|---|---|
| **Entropy** | Randomness of encrypted image (Shannon) | Close to 8.0 bits |
| **NPCR** | % pixels changed when 1 original pixel changes | ~99.61% |
| **UACI** | Average intensity difference after 1-pixel change | ~33.46% |
| **Correlation** | Spatial predictability between adjacent pixels | Close to 0 |
| **PSNR** | Decryption fidelity | ∞ = perfect reconstruction |

## Challenges & Solutions

- **Bogdanov bijectivity constraint:** The Bogdanov map only produces a valid (bijective) pixel permutation for square images. Non-square inputs cause coordinate collisions. Solution: all inputs are resized to 256×256 before processing, and the implementation includes an explicit bijectivity check that raises an error otherwise.
- **Diffusion round reduction:** The reference algorithm used N = 50 XOR diffusion rounds. NPCR/UACI saturation analysis showed the metrics plateau after N = 2, enabling a 25× reduction in encryption time with no measurable security loss.
- **Logistic map transient regime:** Early iterations of the Logistic map exhibit non-chaotic behavior before entering the attractor. The first Q = 100 values are discarded to ensure only fully chaotic output is used as key material.

## Future Improvements

- GPU parallelization of the Tent map XOR stage for further speed gains
- Extension to video encryption (frame-by-frame with inter-frame key chaining)
- Python/NumPy port for deployment outside MATLAB
- Resistance analysis against chosen-plaintext attacks
