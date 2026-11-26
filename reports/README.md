# QA reports

Each report is one Markdown file. The GitHub issue for the report gives the result and a short summary, and links to the file.

## Path

`reports/<project>/<subject>/<date>-<issue>-<slug>.md`

| Part | Meaning | Example |
| --- | --- | --- |
| `<project>` | `logos` or `status` | `logos` |
| `<subject>` | Same as in `evidence/`: the Request for Proposal (RFP) for Logos, the code repo for Status | `rfp-004-dex` |
| `<date>` | The audit date, not the commit date | `2026-11-25` |
| `<issue>` | The iftech/qa-audits issue for this report | `9` |
| `<slug>` | A few words, lowercase, joined with `-` | `audit-report` |

Example: `reports/logos/rfp-004-dex/2026-11-25-9-audit-report.md`.

Images or files that only the report uses go in a folder with the same name, next to the file: `reports/logos/rfp-004-dex/2026-11-25-9-audit-report/`.

## Rules

- **Start from the template.** Use [`templates/report.md`](../templates/report.md) for the file and [`templates/report-issue.md`](../templates/report-issue.md) for the GitHub issue.
- **Link evidence with relative links**, for example `../../../evidence/logos/rfp-004-dex/14-live-basecamp/2026-11-25/`. Relative links work on GitHub, at any commit and inside a bundle.
- **List all evidence in the report's Evidence table.** Add the report to the Report column of `evidence/<project>/README.md`.
- **Fix small mistakes in place** and note the change in the report's version line. Git keeps the old text.
- **Version corrections to released reports.** Once the correction is on `main`, create a new tag with a version suffix, for example `logos-rfp-004-dex-2026-11-25-v2`. Publish a new release with a fresh bundle built from that tag. Update the report and Download links in the issue to use the new tag. Keep the old tag and release.
- **A new audit at a new code revision gets a new file** with a new date. Do not overwrite the old report.
- **Public repo.** Do not include private paths, private repo names, account data or keys.

## Draft reports

Keep a draft report on its own branch in a draft pull request. Mark the report `Status: Draft`. Evidence can merge to `main` as it lands, but only merge the report when its status is `Final`. Do not tag a draft.

To share a draft, open the file on the branch in GitHub, press `y` and share the commit link.

## Send a report with its evidence

To give someone a download link, use a GitHub release. The uploaded bundle zip contains just the report, its own files, the evidence run folders it links and a checksum file. GitHub also adds two `Source code` archives of the whole repository at the tag. You cannot remove those archives from the release.

1. Wait until the report and all linked evidence are on `main`. Tag a commit on `main` that contains both, for example with `logos-rfp-004-dex-2026-11-25`. They can merge on different days.
2. Build the zip from the tag:

   ```sh
   tools/make-report-bundle.sh logos-rfp-004-dex-2026-11-25 reports/logos/rfp-004-dex/2026-11-25-9-audit-report.md
   ```

   The script writes `<tag>.zip`, replacing any `/` in the tag with `-`, and prints the zip's SHA-256 checksum.
3. Create the release on the tag and attach the bundle zip. Name the file to download and give its checksum in the release notes. For example: “Download `logos-rfp-004-dex-2026-11-25.zip` (SHA-256: `<checksum>`).”

Inside the zip, the folders keep their repo paths, so the report's links still work after unzipping. `SHA256SUMS` lists a checksum for every file. To check the files, run `shasum -a 256 -c SHA256SUMS` in the unzipped folder.

If you do not need a download link, build the zip locally from the tag and send it directly. You do not need to create a GitHub release.

To send only the report link, open the report on GitHub and press `y`. The link then points to that commit and does not change.
