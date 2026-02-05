"""
GitHub Brain Loader for OpenClaw
Fetches knowledge base files from GitHub repository
"""

import os
import requests
import time
from pathlib import Path
from typing import Optional, Dict
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class GitHubBrain:
    def __init__(
        self,
        repo: str,
        branch: str = "main",
        token: Optional[str] = None,
        cache_dir: str = "/tmp/brain_cache"
    ):
        self.repo = repo
        self.branch = branch
        self.token = token
        self.cache_dir = Path(cache_dir)
        self.cache_dir.mkdir(exist_ok=True)
        self.base_url = f"https://raw.githubusercontent.com/{repo}/{branch}"

    def _get_headers(self) -> Dict[str, str]:
        """Get request headers with authentication"""
        headers = {}
        if self.token:
            headers["Authorization"] = f"token {self.token}"
        return headers

    def fetch_file(self, file_path: str, use_cache: bool = True) -> str:
        """
        Fetch a file from the GitHub brain repository

        Args:
            file_path: Path to file in repo (e.g., "template/config/vision.md")
            use_cache: Whether to use cached version if available

        Returns:
            File contents as string
        """
        # Check cache first
        cache_file = self.cache_dir / file_path.replace("/", "_")
        if use_cache and cache_file.exists():
            cache_age = time.time() - cache_file.stat().st_mtime
            if cache_age < 300:  # Cache valid for 5 minutes
                logger.info(f"Using cached version of {file_path}")
                return cache_file.read_text()

        # Fetch from GitHub
        url = f"{self.base_url}/{file_path}"
        try:
            response = requests.get(url, headers=self._get_headers(), timeout=10)
            response.raise_for_status()
            content = response.text

            # Update cache
            cache_file.write_text(content)
            logger.info(f"Fetched and cached {file_path}")

            return content
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to fetch {file_path}: {str(e)}")
            # Fall back to cache if fetch fails
            if cache_file.exists():
                logger.warning(f"Using stale cache for {file_path}")
                return cache_file.read_text()
            raise

    def fetch_playbook(self, stage: str, playbook_name: str) -> str:
        """
        Fetch a specific playbook by stage and name

        Args:
            stage: Funnel stage (attract, convert, nurture, deliver)
            playbook_name: Name of the playbook file (without .md extension)

        Returns:
            Playbook contents as string
        """
        file_path = f"template/playbooks/{stage}/{playbook_name}.md"
        return self.fetch_file(file_path)

    def get_brand_voice(self) -> str:
        """Get brand voice guidelines"""
        return self.fetch_file("template/brand/brand.md")

    def get_company_overview(self) -> str:
        """Get company vision and mission"""
        return self.fetch_file("template/config/vision.md")

    def get_offers(self) -> str:
        """Get product/service offerings"""
        return self.fetch_file("template/config/offers.md")

    def get_tech_stack(self) -> str:
        """Get technology stack information"""
        return self.fetch_file("template/config/tech-stack.md")

    def get_social_bios(self) -> str:
        """Get social media bios"""
        return self.fetch_file("template/brand/social-bios.md")

    def get_roles(self) -> str:
        """Get team roles and responsibilities"""
        return self.fetch_file("template/execution/roles.md")

    def sync_all(self):
        """Pre-load all critical files into cache"""
        critical_files = [
            "template/config/vision.md",
            "template/config/offers.md",
            "template/config/tech-stack.md",
            "template/brand/brand.md",
            "template/brand/social-bios.md",
            "template/execution/roles.md",
            "template/execution/project-management.md",
            "template/execution/financials.md",
            "template/execution/reporting.md",
        ]

        for file_path in critical_files:
            try:
                self.fetch_file(file_path, use_cache=False)
            except Exception as e:
                logger.error(f"Failed to sync {file_path}: {str(e)}")


# Initialize brain instance from environment variables
brain = GitHubBrain(
    repo=os.getenv("GITHUB_BRAIN_REPO", ""),
    branch=os.getenv("GITHUB_BRAIN_BRANCH", "main"),
    token=os.getenv("GITHUB_ACCESS_TOKEN"),
    cache_dir=os.getenv("BRAIN_CACHE_DIR", "/tmp/openclaw_brain")
)

# Auto-sync on import if repo is configured
if brain.repo:
    brain.sync_all()
