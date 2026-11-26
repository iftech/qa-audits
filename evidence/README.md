# QA evidence

Evidence files for QA reports: logs, scripts, screenshots and recordings. Reports are in [`reports/`](../reports/) and link to the run folders here.

## Path

`evidence/<project>/<subject>/<issue>-<slug>/<run>/`

| Project | Subject | Issue | Run |
| --- | --- | --- | --- |
| `logos` | The RFP, for example `rfp-004-dex` | The iftech/qa-audits issue number | The date, for example `2026-11-25`. A second run on the same day is `2026-11-25-2` |
| `status` | The code repo: `status-app` or `status-go` | That repo's issue number | `<date>-<platform>`. A second run on the same day and platform is `2026-11-25-android-pixel8-2` |

Status uses the code repo as the subject because issue numbers repeat across the two repos.
For `<platform>`, use `android-<device>`, `ios-<device>`, `macos`, `windows` or `linux`.
Keep the full OS release and device details in the [run README](../templates/run-readme.md), not in the folder name.

## Rules

- **Each run folder has a `README.md`.** Start from [`templates/run-readme.md`](../templates/run-readme.md). It links the issue, the QA comment and the report, gives the start time in UTC and says how to rerun.
- **More than one run on the same day:** add `-2`, `-3` and so on to the run folder name. The first run has no number. The `README.md` gives the exact start time.
- **Code repos and SHAs go in the run folder's README, not in the path.** One issue can use several repos.
- **Status run READMEs also list the QA tree issue and requirement IDs**, for example status-app#22522 R26.
- **A rerun gets a new run folder**, for example a fix check. Never change an old run folder.
- **Only redacted screenshots, logs and recordings go in.** No account data, keys, personal paths or hostnames.
