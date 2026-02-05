"""
Brain Validation Script
Checks that all required files exist and are properly formatted
"""

import os
from pathlib import Path

REQUIRED_FILES = [
    "README.md",
    "SETUP-GUIDE.md",
    "TEMPLATE-CUSTOMIZATION-GUIDE.md",
    ".gitignore",
    ".env.example",
    "_master/docs/architecture.md",
    "_master/docs/best-practices.md",
    "_master/docs/api-reference.md",
    "_master/docs/troubleshooting.md",
    "_master/scripts/brain_loader.py",
    "_master/scripts/validate-brain.py",
    "template/config/vision.md",
    "template/config/offers.md",
    "template/config/tech-stack.md",
    "template/brand/brand.md",
    "template/brand/social-bios.md",
    "template/playbooks/README.md",
    "template/execution/roles.md",
    "template/execution/project-management.md",
    "template/execution/financials.md",
    "template/execution/reporting.md",
    "template/setup/openclaw.md",
    "template/setup/api-connections.md",
]

REQUIRED_FOLDERS = [
    "_master",
    "_master/docs",
    "_master/scripts",
    "_master/templates",
    "template",
    "template/config",
    "template/brand",
    "template/brand/assets",
    "template/playbooks",
    "template/playbooks/attract",
    "template/playbooks/convert",
    "template/playbooks/nurture",
    "template/playbooks/deliver",
    "template/execution",
    "template/setup",
    "template/memory",
    "examples",
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
