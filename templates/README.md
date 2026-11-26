# Templates

Copy a template, then replace every `<...>` placeholder. Delete the guidance lines that start with `>`.

| Template | Copy it to | Use it for |
| --- | --- | --- |
| [`report.md`](report.md) | `reports/<project>/<subject>/<date>-<issue>-<slug>.md` | The full Logos QA report |
| [`report-issue.md`](report-issue.md) | The body of the `[REPORT]` GitHub issue | The short issue that links to the report file |
| [`project-index.md`](project-index.md) | `evidence/<project>/README.md` | The list of issue folders, runs and reports for one project |
| [`run-readme.md`](run-readme.md) | `evidence/<project>/<subject>/<issue>-<slug>/<run>/README.md` | One test run: what was tested, how to rerun it, what each file shows |

The report templates follow the Logos audit report format. Status reports and run folders follow the Status rules in [`evidence/status/README.md`](../evidence/status/README.md).
