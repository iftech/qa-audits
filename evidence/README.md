# QA evidence

Evidence files for QA reports: logs, scripts, screenshots and recordings. The report itself is the issue comment that links here.

## Path

`evidence/<project>/<subject>/<issue>-<slug>/<run>/`

| Project | Subject | Issue | Run |
| --- | --- | --- | --- |
| `logos` | The RFP, for example `rfp-004-dex` | The iftech/qa-audits issue number | The date, for example `2026-11-25` |
| `status` | The code repo: `status-app` or `status-go` | That repo's issue number | `<date>-<platform>`, for example `2026-11-25-android-pixel8` |

Status uses the code repo as the subject because issue numbers repeat across the two repos.

## Rules

- **Each run folder has a `README.md`.** It links the issue and the QA comment, and says how to rerun.
- **Code repos and SHAs go in the run folder's README, not in the path.** One issue can use several repos.
- **Status run READMEs also list the QA tree issue and requirement IDs**, for example status-app#22522 R26.
- **A rerun gets a new run folder**, for example a fix check. Never change an old run folder.
- **Only redacted screenshots, logs and recordings go in.** No account data, keys, personal paths or hostnames.
