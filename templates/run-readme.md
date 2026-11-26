# <RFP-NNN or repo> #<issue>: <issue title> (run <run>)

> Copy to `evidence/<project>/<subject>/<issue>-<slug>/<run>/README.md`. Use `iftech/qa-audits` as the issue repo for Logos and the code repo for Status. Never change a run folder after its run. A rerun gets a new run folder.
> Use the `iftech/qa-audits` report issue number for `<report-issue>`.

- **Issue:** [<issue-repo>#<issue>](https://github.com/<issue-repo>/issues/<issue>)
- **QA tree issue and requirement IDs (Status only):** <link to the QA tree issue>, <IDs, e.g. R26>
- **QA comment:** <link to the issue comment with the result>
- **Report:** [`<date>-<report-issue>-<report-slug>.md`](../../../../../reports/<project>/<subject>/<date>-<report-issue>-<report-slug>.md), or "none"
- **Run started:** <YYYY-MM-DD HH:MM> UTC

## Code and spec

- Code: [`<org>/<repo>@<full sha>`](https://github.com/<org>/<repo>/tree/<full sha>) (<version or tag>)
- <Other repo>: [`<org>/<repo>@<full sha>`](https://github.com/<org>/<repo>/tree/<full sha>)
- Spec: [`logos-co/rfp@<full sha>`](https://github.com/logos-co/rfp/blob/<full sha>/RFPs/<file>.md)
- Tools: <tool and version, for example Rust `1.94.0`>
- Platform: <OS name and release>; <device model or CPU architecture if there is no device model>
- Environment: <where the test ran, for example a real device, BrowserStack, an emulator or simulator, Docker, or a CI runner; include the session or job link if available>

> For BrowserStack, link the session page (login needed) and name the redacted recording file saved in this run folder so readers without a login can view it. Example: BrowserStack, [session](<url>) (login needed); recording: `recording.mp4`.

> Use the OS release shown on the test target, not an API level or kernel version. For Linux, name the distribution. Use the product model name and add the model identifier in parentheses if it distinguishes the variant. If only the identifier is available, use it.
>
> Examples: `Android 14; Google Pixel 8`, `iOS 17.5.1; iPhone 15`, `macOS 15.1; Mac mini (M2, 2023)`, `Windows 11 23H2; Surface Laptop 5`, `Ubuntu 22.04.5; x86_64`.

## Build (Status only)

- Build source: <CI run link or "local build">
- App version: <version>
- status-go SHA pinned by status-app: <full SHA>
- Non-default feature flags: <for example "Threads on, custom build", or "none">

## Why this run

<One sentence. For example: "First run." or "Rerun of 2026-11-25 to check fix <short sha>.">

## How to rerun

<Exact steps or the script to run, with its arguments.>

## Files

| File or folder | What it shows |
| --- | --- |
| `<file>` | <One line> |
