#!/usr/bin/env bash
# Apply the repo policy package to an existing GitHub repository and lock main.
# Usage: apply.sh <owner/repo> <ruby|node|python|go|none> [--skip-ruleset]
# Requires: gh (authed), git, ssh access to the repo.
set -euo pipefail

usage() {
	echo "Usage: $0 <owner/repo> <ruby|node|python|go|none> [--skip-ruleset]" >&2
	exit 1
}
[ $# -ge 2 ] || usage
repo=$1
lang=$2
skip_ruleset=${3:-}
case "$lang" in ruby | node | python | go | none) ;; *) usage ;; esac
here="$(cd "$(dirname "$0")" && pwd)"
repo_name=${repo#*/}

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
git clone --depth 1 "git@github.com:$repo.git" "$work/repo"
cd "$work/repo"
git branch --show-current | grep -qx main || {
	echo "default branch is not main, aborting" >&2
	exit 1
}

# Shared package (never overwrite existing files; adapt manually when present).
for f in .github/pull_request_template.md .github/ISSUE_TEMPLATE/bug_report.yml \
	.github/ISSUE_TEMPLATE/feature_request.yml .github/ISSUE_TEMPLATE/config.yml; do
	mkdir -p "$(dirname "$f")"
	[ -f "$f" ] || cp "$here/$f" "$f"
done
# config.yml links point to the repo; resolve the OWNER/REPO placeholder.
sed -i "s|OWNER/REPO|$repo|g" .github/ISSUE_TEMPLATE/config.yml
[ -f SECURITY.md ] || cp "$here/SECURITY.md" SECURITY.md
if [ ! -f CONTRIBUTING.md ]; then
	cp "$here/CONTRIBUTING.md" CONTRIBUTING.md
	echo "NOTE: CONTRIBUTING.md is a skeleton, adapt the Setup/Commands section to the toolchain." >&2
fi
[ -f AGENTS.md ] || cp "$here/AGENTS.md" AGENTS.md

# CI skeleton only when a standard one applies and no workflow exists yet.
if [ "$lang" != "none" ] && [ ! -f .github/workflows/ci.yml ]; then
	mkdir -p .github/workflows
	cp "$here/templates/ci/$lang.yml" .github/workflows/ci.yml
	echo "NOTE: CI skeleton installed, adapt build/test commands." >&2
fi

# Per-language dependabot (none -> actions only).
dep_lang=$lang
[ "$lang" = "none" ] && dep_lang=actions
[ -f .github/dependabot.yml ] || cp "$here/templates/dependabot/$dep_lang.yml" .github/dependabot.yml

if [ -n "$(git status --porcelain)" ]; then
	git add -A
	git commit -q -m "chore(repo): apply repo policy (templates, dependabot, security, ci)"
	git push origin main
else
	echo "nothing to commit, files already up to date"
fi

[ "$skip_ruleset" = "--skip-ruleset" ] && exit 0

# Lock main: ruleset replicating opencode-mesh protect-main.
gh api -X POST "repos/$repo/rulesets" --input - <<'JSON'
{
  "name": "protect-main",
  "target": "branch",
  "enforcement": "active",
  "conditions": {"ref_name": {"include": ["refs/heads/main"], "exclude": []}},
  "bypass_actors": [],
  "rules": [
    {"type": "deletion"},
    {"type": "non_fast_forward"},
    {"type": "pull_request", "parameters": {
      "required_approving_review_count": 0,
      "dismiss_stale_reviews_on_push": true,
      "require_code_owner_review": false,
      "require_last_push_approval": false,
      "required_review_thread_resolution": false,
      "required_reviewers": [],
      "allowed_merge_methods": ["squash"]
    }}
  ]
}
JSON
echo "policy applied to $repo"
