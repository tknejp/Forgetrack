from pathlib import Path
from PIL import Image

INPUT_DIR = Path("input")
OUTPUT_DIR = Path("output")

TARGET_SIZE = (512, 512)

SUPPORTED_EXTENSIONS = {
    ".png",
    ".jpg",
    ".jpeg",
    ".webp",
    ".bmp",
}

def resize_images(input_dir: Path, output_dir: Path) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)

    for image_path in input_dir.iterdir():
        if not image_path.is_file():
            continue

        if image_path.suffix.lower() not in SUPPORTED_EXTENSIONS:
            continue

        output_path = output_dir / image_path.name

        try:
            with Image.open(image_path) as img:
                # Zachová alpha kanál u PNG/WebP, pokud existuje
                if img.mode in ("RGBA", "LA"):
                    resized = img.resize(TARGET_SIZE, Image.Resampling.LANCZOS)
                else:
                    resized = img.convert("RGB").resize(
                        TARGET_SIZE,
                        Image.Resampling.LANCZOS,
                    )

                resized.save(output_path)

            print(f"OK: {image_path.name} -> {output_path}")

        except Exception as e:
            print(f"ERROR: {image_path.name}: {e}")

if __name__ == "__main__":
    resize_images(INPUT_DIR, OUTPUT_DIR)