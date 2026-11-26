> Title: `[REPORT] [RFP-NNN] <name>: QA audit report (<repo>@<short sha>)`. No labels. Link this issue from the epic with one line: `QA audit report: #<this issue>`.

**Result:** <Pass | Pass with findings | Pass, except for <ID> | Fail>

**Status:** <Draft | Final>

> For `<report-ref>`, use the commit SHA for a draft. For a final report without a release, use a commit SHA or tag. If you keep the Download line, use the same release tag for `<report-ref>` and `<release-tag>`.

**Full report:** [`reports/<project>/<subject>/<date>-<issue>-<slug>.md`](https://github.com/iftech/qa-audits/blob/<report-ref>/reports/<project>/<subject>/<date>-<issue>-<slug>.md) (Report v<N>, <YYYY-MM-DD>)

> Keep the Download line only for a final report with a GitHub release. Delete it if there is no release.

**Download:** [report and evidence (zip)](https://github.com/iftech/qa-audits/releases/tag/<release-tag>)

## Summary

<Two to four sentences. Name the RFP, repo and tested revision. Give the result and the most important impact.>

**Not tested:** <What was in scope but not checked, or "none".>

| Class | High | Medium | Low | Info | Total |
| --- | ---: | ---: | ---: | ---: | ---: |
| Total | 0 | 0 | 0 | 0 | 0 |

## Decisions for the specification owner

1. <Decision needed, tied to a finding ID. Or "None.">
