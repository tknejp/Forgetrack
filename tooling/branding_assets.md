Branding asset notes for Forgetrack.

Source and derived files:
- `assets/branding/app-icon.png`: original imported source asset
- `assets/branding/app-icon-foreground.png`: transparent optimized foreground used in-app when needed
- `assets/branding/app-icon-square.png`: square derived master used for platform icon generation
- `assets/branding/wordmark-dark.svg`: wordmark for light backgrounds
- `assets/branding/wordmark-light.svg`: wordmark for dark backgrounds
- `assets/branding/wordmark-gradient.svg`: optional marketing/readme variant

Generated platform assets are produced by:
- `tooling/generate_branding_assets.ps1`

Recommended refresh workflow:
1. Replace the source logo file.
2. Run the PowerShell generator script.
3. Review the regenerated platform icons before committing.

Avoid hand-editing generated platform icon files unless you intentionally want a one-off override.
