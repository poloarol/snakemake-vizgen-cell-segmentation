import argparse
import csv
from pathlib import Path
from typing import Any

import yaml


REPO_ROOT = Path(__file__).resolve().parents[1]
REQUIRED_INPUTS = (
    Path("images/micron_to_mosaic_pixel_transform.csv"),
    Path("detected_transcripts.csv"),
)
SAMPLESHEET_COLUMNS = (
    "sample_name",
    "path_to_sample",
    "algorithm",
    "cellpose_configuration",
)


def load_config(config_path: Path) -> dict[str, Any]:
    with config_path.open(encoding="utf-8") as config_file:
        config = yaml.safe_load(config_file)
    if not isinstance(config, dict):
        raise ValueError(f"Configuration must be a YAML mapping: {config_path}")
    return config


def path_for_samplesheet(path: Path) -> str:
    try:
        return path.relative_to(REPO_ROOT).as_posix()
    except ValueError:
        return str(path)


def create_samplesheet(algorithm: str, model: str, config_path: Path, output_path: Path) -> None:
    config = load_config(config_path)
    data_config = config["data"]
    input_root = Path(data_config["input"])
    if not input_root.is_absolute():
        input_root = REPO_ROOT / input_root
    input_root = input_root.resolve()
    if not input_root.is_dir():
        raise FileNotFoundError(f"Input directory does not exist: {input_root}")

    if algorithm == "cellpose":
        if model not in {"one", "two", "three"}:
            raise ValueError("Cellpose model must be one of: one, two, or three")
        cellpose_configuration = config["algo"]["cp"][model]
    elif algorithm == "watershed":
        cellpose_configuration = ""
    else:
        raise ValueError("algorithm must be either 'watershed' or 'cellpose'")

    samples = sorted(
        sample_dir
        for sample_dir in input_root.iterdir()
        if sample_dir.is_dir() and (sample_dir / "images").is_dir()
    )
    if not samples:
        raise ValueError(
            f"No sample directories containing an images/ directory were found in {input_root}"
        )

    rows = []
    for sample_dir in samples:
        missing_inputs = [
            sample_dir / required_input
            for required_input in REQUIRED_INPUTS
            if not (sample_dir / required_input).is_file()
        ]
        if missing_inputs:
            missing = ", ".join(str(path) for path in missing_inputs)
            raise FileNotFoundError(
                f"Sample {sample_dir.name!r} is missing required input(s): {missing}"
            )
        rows.append(
            {
                "sample_name": sample_dir.name,
                "path_to_sample": path_for_samplesheet(sample_dir),
                "algorithm": algorithm,
                "cellpose_configuration": cellpose_configuration,
            }
        )

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", newline="", encoding="utf-8") as samplesheet:
        writer = csv.DictWriter(samplesheet, fieldnames=SAMPLESHEET_COLUMNS)
        writer.writeheader()
        writer.writerows(rows)

    print(f"Wrote {len(rows)} sample(s) to {output_path}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Create a samplesheet from the workflow configuration and input samples."
    )
    parser.add_argument(
        "--algorithm",
        type=str,
        choices=["watershed", "cellpose"],
        required=True,
        help="Segmentation algorithm to use (watershed or cellpose)",
    )
    parser.add_argument(
        "--model",
        type=str,
        choices=["one", "two", "three"],
        help="Cellpose model to use (required if algorithm is cellpose)",
    )
    parser.add_argument(
        "--config",
        type=Path,
        default=REPO_ROOT / "config" / "config.yml",
        help="Workflow YAML configuration (default: config/config.yml)",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=REPO_ROOT / "samplesheet.csv",
        help="Output CSV path (default: samplesheet.csv in the repository root)",
    )
    args = parser.parse_args()
    create_samplesheet(args.algorithm, args.model, args.config, args.output)


if __name__ == "__main__":
    main()
