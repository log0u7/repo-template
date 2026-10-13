# GitLab notes

This repository serves GitHub and GitLab from one source. On GitLab repos:

- Copy `gitlab/.gitlab-ci.yml` to the repo root as `.gitlab-ci.yml`.
- Copy `gitlab/issue_templates/*.md` to `.gitlab/issue_templates/`.
- Copy `gitlab/merge_request_templates/default.md` to
  `.gitlab/merge_request_templates/`.
- Branch protection: Settings -> Repository -> Protected branches
  (`main`: no push allowed, maintainers merge), plus
  Settings -> Merge requests -> merge checks as needed.
- Shared CI: when a group has common CI files
  (e.g. `6admin.io/docker/common_ci`), include them instead of duplicating:

```yaml
include:
  - project: 6admin.io/docker/common_ci
    ref: main
    file: <shared-file>.yml
```

GitHub-only files (`.github/dependabot.yml`, `ISSUE_TEMPLATE/`) are inert on
GitLab and vice versa (`gitlab/`, `.gitlab-ci.yml` are ignored by GitHub), so
one template serves both platforms without duplication.
