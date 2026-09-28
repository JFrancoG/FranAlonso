# Accessibility review output

Lead with P0–P3 findings. Include absolute file/line, criterion or repository rule, evidence, user impact and minimum
recommended direction without a patch.

Then report:

- UI diff and flows audited.
- Read-only evidence mode: enforced sandbox or matching operational pre/post digest.
- Preview variants rendered and visually inspected.
- Criterion register coverage.
- Static, Inspector and manual assistive-technology evidence separately.
- Pending validation and residual risks.
- Gate evaluated: functional demo or integral accessibility validation.
- Gate result: pass, correct before proceeding, blocked, or N/A. For an ADR 0029 functional pass, name the linked
  deferred-work issue, owner and recovery trigger; report integral validation separately as pending when incomplete.

`Sin hallazgos` does not convert missing runtime evidence into a pass.
Deferral preserves each `Falla`, `Pendiente` or `Limitado` result; it never converts it into `N/A` or `Pasa`.
