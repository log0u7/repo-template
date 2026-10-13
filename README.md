# repo-template

One policy package for every repository: branch protection, PR and issue
templates, dependabot, security policy, CONTRIBUTING and CI skeletons.
Write it once here, apply it everywhere, audit it everywhere.

## Why this exists

Maintaining the same contribution policy across ten repositories by hand
drifts: one repo gets templates, another gets a locked branch, none agree.
This repository is the single source of truth. Applying it is one command
and the result is auditable with one API call.

## Quickstart: protect a new repository

1. Create the repo (or press **Use this template** on GitHub).

   ```sh
   gh repo create log0u7/<name> --public --clone && cd <name>
   ```

2. Apply the policy for the project's language:

   ```sh
   /path/to/repo-template/apply.sh log0u7/<name> node   # or ruby | python
   ```

3. Verify the lock: pushing directly to `main` is now rejected - changes
   land through pull requests only.

## How-to: apply the policy to an existing repository

```sh
apply.sh <owner/repo> <ruby|node|python> [--skip-ruleset]
```

- Existing files are never overwritten; skeletons are added only where
  missing. `CONTRIBUTING.md` and the CI skeleton may still need adapting
  to the real toolchain (the script prints a reminder).
- `--skip-ruleset` applies the files without locking `main` (use when the
  branch is already protected or when rulesets are unavailable).

## How-to: adapt the skeletons

| File | Adapt when | What to change |
| ------ | ----------- | ---------------- |
| `CONTRIBUTING.md` | always | Setup/commands section to the actual toolchain |
| `templates/ci/<lang>.yml` | if no CI exists | build/test commands for the project |
| `templates/dependabot/<lang>.yml` | per-language deps | extra ecosystems |
| `AGENTS.md` | optional | project-specific rules for coding agents |

## Reference: repository layout

| Path | Role | Copied by apply.sh |
| ------ | ------- | -------------------- |
| `.github/pull_request_template.md` | PR checklist and flow | yes, if absent |
| `.github/ISSUE_TEMPLATE/*.yml` | bug/feature forms + config | yes, if absent |
| `.github/dependabot.yml` | dependency updates | per-language variant |
| `templates/ci/<lang>.yml` | CI skeleton | yes, if no `ci.yml` |
| `templates/dependabot/<lang>.yml` | per-language dependabot | yes, if absent |
| `SECURITY.md` | private vulnerability reporting policy | yes, if absent |
| `CONTRIBUTING.md` | gitflow, commits, PR flow, releases | yes, if absent |
| `AGENTS.md` | coding agent rules | yes, if absent (skeleton) |
| `apply.sh` | applier and branch-locker | never copied |
| `gitlab/` | GitLab equivalents | see `gitlab/README-gitlab.md` |

## Reference: what `protect-main` enforces

A repository ruleset named `protect-main`, active on `refs/heads/main`:

- deletions blocked, force pushes blocked (`non_fast_forward`)
- every change lands through a pull request
- 0 required approving reviews: the solo maintainer self-merges own PRs
- merge commit only

CI green is expected before merging but not enforced by the ruleset yet.

## Explanation: GitHub and GitLab

One repository serves both platforms. GitHub files live in `.github/`
(`dependabot.yml`, `ISSUE_TEMPLATE/`, `pull_request_template.md`); GitLab
templates live in `.gitlab/` (`issue_templates/`, `merge_request_templates/`)
and CI in `.gitlab-ci.yml`. Both directories ship in this template and are
inert on the other platform, so nothing is duplicated.

GitLab CI composes with existing shared CI where it exists - for example the
`6admin.io/docker/common_ci` project is included with:

```yaml
include:
  - project: 6admin.io/docker/common_ci
    ref: main
    file: <shared-file>.yml
```

The rationale for 0 required approvals and self-merging: the maintainer is
currently the single author, and GitHub blocks self-approval, so a review
requirement would deadlock every change. It becomes a review gate the day a
second contributor lands.
