# 13.9 — PDF Storage validation evidence

Local implementation PLU-105; authorization03/10/2026, validation04/10 Europe/Madrid.
No Git delivery, Done, actual Firebase Storage, live activation or13.10.
[Proposal and primary sources](13-9-billing-storage-proposal.md), [phase record](phase-13.md).

## PRE and RED

PRE `billing_13_9_pre`: PASS, noP0–P3.1011tracked/nonignored untracked files, root/reviewer initial/final
SHA256 `b8f43f97cd0608ad26dcc702a2dd366ac5753c04433033b868776604ce7a79d1` identical.

Xcode MCP stable workspace-PfnUYLlMzY, Develop, iPadPro13M5 arm64 Simulator27.2/SDK27.0;
Swift6/strict complete/defaultnonisolated, iOS27 actual settings.
Native GetTestList discovers22new declarations in BillingDocumentPDFStorageRepositoryTests and
UploadBillingDocumentPDFUseCaseTests (12+10); full list7E054294-12A0-49D6-B2DD-CAB75F812233.txt.
Initial compile attempt found missing `try` in the new UUID fixture; compile-only correction, no GREEN behavior.
The failed build is not RED evidence. GetBuildLog10301EAA-605C-4D4E-A477-F3D6C1AF510B.txt retains that diagnostic.

Behavioral RED00:06:49:43cases,42failed/1passed(default unavailable composition),0skip/notRun.
RunSomeTests/3A2403B3-F60B-4EB2-9CB0-94C348180D3A.txt and
RunSomeTests/Test-FranAlonso-Develop-2026.10.04_00-06-49-+0200.xcresult.
Root artifact directory `/var/folders/wt/r327qtw12_s5tbbcnx9dzqv80000gn/T/ActionArtifacts/default/`.
Native JSON `/tmp/franalonso-13-9-red-tests.json`:22declarations,8parameter groups/29arguments;
21failed declarations,1passed. Failure messages show unavailable stubs, not missing APIs or compilation failure.

## GREEN, regression and builds

- GREEN00:10:24:43/43cases,22declarations,8complete parameter groups/29arguments.
  RunSomeTests/5AC17EA0-B8B9-4D29-B538-D3DCD20F7A8B.txt.
  The MCP-reported copied xcresult lacks Info.plist; the matching original valid bundle was read from
  `/Users/jesusf/Library/Developer/Xcode/DerivedData/FranAlonso-eehpkvodmpnqlchgeqriatcucsjf/Logs/Test/`:
  Test-FranAlonso-Develop-2026.10.04_00-10-24-+0200.xcresult. No repeat run was needed.
- Focal00:11:55:181/181cases,91declarations,38complete groups/128arguments in8suites;
  Storage/upload/render/document/request/reservation/Store/auth-root regression.
  RunSomeTests/30F7944F-995B-49E6-91AC-D2FC5A7A7E8D.txt and matching native xcresult.
- One global00:12:29:2787/2787cases,1683declarations,364complete groups/1468arguments.
  RunAllTests/447FD769-4934-4D4C-9C03-ACC09306AFE6.txt and matching native xcresult.
  Every run has0failed/skipped/notRun/expectedFailures. Stock118 passed with unchanged source; no fix or stability claim.
- Native JSON inspected: `/tmp/franalonso-13-9-green-tests.json`, `-focused-tests.json`, `-global-tests.json`.
- Develop buildForTesting00:13:08 PASS4.011s; Production00:13:50 PASS23.752s.
  BuildProject/BuildProject-Log-20261004-001308.txt and -20261004-001350.txt.
  Full logs12,683/17,158lines:0Swift/Clang errors/warnings, only2/1known AppIntents metadata notices.
  Incremental builds, not clean-build certification. Develop/plan/M5 destination restored.
- 10new Swift files each have0diagnostics via Xcode MCP.7production/3tests+fixtures, no existing Swift/config/resource
  changed. Prepared PDFs and actual3page renderer output,100pages and exactly32MiB accepted unchanged;
  101pages/32MiB+1 rejected.
  Independent literal SHA256/path oracle;8binding mutations preserve original document/PDF; concurrent equal/divergent,
  offline/permission, lost response and early/late cancellation, revoked capabilities and foreign receipts covered.
- Initial Swift source manifest `/tmp/franalonso-13-9-before-style-swift-manifest.json`,10files aggregate
  `5d1ef3a5bbb7652239c2df3cdf5b3f15bd5094c932d4a6de2b0247c13e01bac2`.
  Identity rechecked after tests/builds. Per-file SHA256 remains in that manifest.
- Source-style recall10files/0candidates plus implementation manual pass; independent audit results below.
- 619catalog entries/0errors, resources unchanged. Governance retains only6pre-existing Desktop08.3broken links;
  diff-check PASS. No new dependency, unsafe escape, PII/logging, bundled signature, live writer or schema change.

## Audit and scope boundaries

Technical POST `billing_13_9_post`: PASS/Sin hallazgosP0–P3 in its technical scope. Independently inspected
all10Swift, authority, full native tests/JSON, complete build logs, proposal/docs and exact call paths.
Technical and initial style audits were operationally read-only with1022files; root/reviewer pre/post identical
SHA256 `5de3d17858557ccf61b6e7c9dc569a46c6f220cc15887488e24c3b7317f84fe3`.
Style found oneP3: InMemory repository guard at49fits119columns and must be horizontal.

Root applied only that guard's spaces/newlines after both audits ended. Non-whitespace bytes match exactly;
proof `/tmp/franalonso-13-9-style-identity.json`, original `/tmp/franalonso-13-9-before-style-InMemoryRepository.swift`.
Other9Swift hashes unchanged. Final manifest `/tmp/franalonso-13-9-swift-manifest.json`, aggregate
`b4c39c49c049f35a275e556a6301bbb0a9a6b4b8dfafd3caf7c6162925d33fdb`.

After correction:43/43cases00:21:44,22declarations/8complete groups/29arguments,0fail/skip/notRun;
RunSomeTests/82E9AB4B-807C-44F6-9FEC-00E8E8A4E3C4.txt and matching native xcresult,
JSON `/tmp/franalonso-13-9-after-style-tests.json`. Develop buildForTesting00:23:38 PASS4.203s,
Production00:24:17 PASS18.203s, incremental. Complete logs11,338/17,119lines:
BuildProject/BuildProject-Log-20261004-002338.txt and -20261004-002417.txt,
0Swift/Clang errors/warnings, only2/1known AppIntents notices. Changed file diagnostics0 after one transient
SourceEditor error5/retry;9unchanged files retain their diagnostic pass. Develop/plan/M5 restored.
The single181focal/global2787 executions and technical POST predate formatting and are retained by proven
whitespace-only impact. No repeated global or technical audit is attributed to this correction.
Focused style re-audit `billing_13_9_style`: PASS/Sin hallazgos restantes; guard119columns and supporting
record inspected,0focal candidates. Operational read-only1022files; root/reviewer initial/final digest identical:
`6a0a0def5e06ded3db0710d99dadee8ad9ce5d57cce6de040a704e599693998e`.
After that freeze only this outcome and operational metadata are recorded; Swift retains its validated identity.
Implementation locally ready; issue/project remain In Progress and delivery/Done await separate authorization.
This does not close the phase or enable real backend, durable process recovery, UI integration or live activation.
Native UI/accessibility/previews/manual PDF visual review N/A: no screen, resource, localization, renderer or
composition consumer changes. Existing13.8 visual evidence applies only to unchanged output sources.
PLU-101 Backlog/Jesus, feedback/stabilization before first real-use candidate;13.6 physical protection limited/pending
and Stock118 historical intermittency retain their own boundaries. No new accessibility deferral.
