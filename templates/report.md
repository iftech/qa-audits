# <RFP-NNN>: <RFP name>

> Copy to `reports/<project>/<subject>/<date>-<issue>-<slug>.md`. Write for a reader who reads English as a second language, is in a hurry and has not seen the discussion. Spell out acronyms on first use.

| Item | Link |
| --- | --- |
| Code | [`<org>/<repo>@<full sha>`](https://github.com/<org>/<repo>/tree/<full sha>) |
| Specification | [<RFP-NNN> @ `<full sha>`](https://github.com/logos-co/rfp/blob/<full sha>/RFPs/<file>.md#<section>) |
| Report issue | [iftech/qa-audits#<issue>](https://github.com/iftech/qa-audits/issues/<issue>) |
| Tracking | [Epic #<epic>](https://github.com/iftech/qa-audits/issues/<epic>) |

**Result:** <Pass | Pass with findings | Pass, except for <ID> | Fail>

**Status:** <Draft | Final>

**Version:** Report v<N>, <YYYY-MM-DD>. <One line on what changed since the last version, or "First version.">

## Summary

<Two to four sentences. Name the RFP, repo and tested revision. Give the result, the most important impact and any scope limit that changes how to read it.>

**Scope:** <What was checked, for example the Hard Requirements sections.>

**Not tested:** <What was in scope but not checked, and why. Or "none".>

<details>
<summary>Severity and pass rule</summary>

- **High:** <one line>
- **Medium:** <one line>
- **Low:** <one line>
- **Info:** <one line>

Pass rule, written before testing: `Pass` = no findings; `Pass with findings` = no High finding open; `Fail` = a High finding open.

</details>

## Counts and results

| Class | High | Medium | Low | Info | Total |
| --- | ---: | ---: | ---: | ---: | ---: |
| Bug | 0 | 0 | 0 | 0 | 0 |
| Outdated spec | 0 | 0 | 0 | 0 | 0 |
| Unverified | 0 | 0 | 0 | 0 | 0 |
| Total | 0 | 0 | 0 | 0 | 0 |

| ID | Severity | Class | Status | Changes the Result? | Finding | Requirement |
| --- | --- | --- | --- | --- | --- | --- |
| [<PFX>-01](#pfx-01-short-title) | <High> | <Bug> | Open | <Yes / No> | <Short title> | <F.1> |

> Status is one of `Open`, `Fixed in <short sha>`, `Accepted` or `Spec to update`. Mark `Fixed` only after you check the fix commit.

## Findings

### <PFX>-01: <Short title>

| Severity | Class | Status | Requirement | Evidence |
| --- | --- | --- | --- | --- |
| <High> | <Bug> | Open | <F.1> | [#<issue> run <date>](../../../evidence/<project>/<subject>/<issue>-<slug>/<run>/) |

<What is wrong.> <Why it matters.> <What to fix.>

<details>
<summary>Requirement text and code</summary>

> <Exact requirement quote>

- [`<file>:<line>`](https://github.com/<org>/<repo>/blob/<full sha>/<file>#L<line>): <what this line shows>

</details>

## Evidence

> List every evidence folder that this report uses. The bundle script collects the folders from these links.

| Issue | Run | What it shows |
| --- | --- | --- |
| [#<issue> <title>](https://github.com/iftech/qa-audits/issues/<issue>) | [`<run>`](../../../evidence/<project>/<subject>/<issue>-<slug>/<run>/) | <One line> |

<details>
<summary>How to reproduce</summary>

- Tool revisions: <tool and version, with commit links>
- Worker image: <image name and tag>
- Model settings: <model per role>
- Briefs and section anchors: <list>
- Test command:

  ```sh
  <command>
  ```

- Access needed: <what a rerun needs, for example a local chain only>

</details>

## Decisions for the specification owner

1. <Decision needed, tied to a finding ID or requirement. Or "None.">
