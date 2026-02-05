"""
Brain Validation Script
Checks that all required files exist and are properly formatted
"""

import os
from pathlib import Path

REQUIRED_FILES = [
    "README.md",
    "SETUP-GUIDE.md",
    ".gitignore",
    ".env.example",
    "config/vision.md",
    "config/offers.md",
    "config/tech-stack.md",
    "brand/brand.md",
    "brand/social-bios.md",
    "playbooks/README.md",
    "execution/roles.md",
    "execution/project-management.md",
    "execution/financials.md",
    "execution/reporting.md",
    "setup/openclaw.md",
    "setup/api-connections.md",
    "scripts/brain_loader.py",
]

REQUIRED_FOLDERS = [
    "config",
    "brand",
    "brand/assets",
    "playbooks",
    "playbooks/attract",
    "playbooks/convert",
    "playbooks/nurture",
    "playbooks/deliver",
    "execution",
    "setup",
    "memory",
    "scripts",
]


def validate():
    """Validate brain structure"""
    root = Path(".")
    errors = []
    warnings = []

    print("Validating Master Brain structure...\n")

    # Check folders
    print("Checking folders...")
    for folder in REQUIRED_FOLDERS:
        folder_path = root / folder
        if not folder_path.exists():
            errors.append(f"Missing required folder: {folder}")
        elif not folder_path.is_dir():
            errors.append(f"Path exists but is not a folder: {folder}")
        else:
            print(f"  [OK] {folder}")

    # Check files
    print("\nChecking files...")
    for file in REQUIRED_FILES:
        file_path = root / file
        if not file_path.exists():
            errors.append(f"Missing required file: {file}")
        elif file_path.stat().st_size == 0:
            warnings.append(f"File is empty: {file}")
            print(f"  [WARN] {file} (empty)")
        else:
            print(f"  [OK] {file}")

    # Check for placeholder content
    print("\nChecking for placeholder content...")
    placeholder_indicators = [
        "[CLIENT NAME]",
        "[YOUR COMPANY NAME]",
        "[ORIGINAL_OWNER]",
        "YOUR_USERNAME",
        "your-username",
    ]

    for file in REQUIRED_FILES:
        file_path = root / file
        if file_path.exists() and file_path.suffix == ".md":
            content = file_path.read_text()
            for placeholder in placeholder_indicators:
                if placeholder in content:
                    warnings.append(f"Placeholder '{placeholder}' found in {file}")

    # Print results
    print("\n" + "=" * 60)
    if errors:
        print(f"\nVALIDATION FAILED - {len(errors)} error(s):\n")
        for error in errors:
            print(f"  - {error}")
    else:
        print("\nVALIDATION PASSED - All required structure present")

    if warnings:
        print(f"\n{len(warnings)} warning(s):\n")
        for warning in warnings:
            print(f"  - {warning}")

    print("\n" + "=" * 60)

    return len(errors) == 0


if __name__ == "__main__":
    success = validate()
    exit(0 if success else 1)
