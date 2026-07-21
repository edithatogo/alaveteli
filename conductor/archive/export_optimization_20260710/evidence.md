# Bulk Export Closeout Evidence

## Provenance

- Issues: [#14](https://github.com/edithatogo/alaveteli/issues/14), [#17](https://github.com/edithatogo/alaveteli/issues/17), and [#34](https://github.com/edithatogo/alaveteli/issues/34).
- Pull request: [#33](https://github.com/edithatogo/alaveteli/pull/33).
- Merge commit: `47deb574af7dc1b88ca9dfb32e3370321141ef55`.
- The final current-base head was `282af3b70621edf1f6b6da2b4cfeed83cf00e181`.

## Hosted Qualification

- Ruby 3.4 core: [job 88267539866](https://github.com/edithatogo/alaveteli/actions/runs/29714078336/job/88267539866)
- Ruby 4.0 core: [job 88267539890](https://github.com/edithatogo/alaveteli/actions/runs/29714078336/job/88267539890)
- Ruby 3.4 gems: [job 88267539873](https://github.com/edithatogo/alaveteli/actions/runs/29714078336/job/88267539873)
- Ruby 4.0 gems: [job 88267539860](https://github.com/edithatogo/alaveteli/actions/runs/29714078336/job/88267539860)
- Security and dependency checks: [security run 29714078376](https://github.com/edithatogo/alaveteli/actions/runs/29714078376)

## Scope

The streamed export, exact-byte ETag snapshot, private revalidation behavior, and regression coverage are merged. The implementation was corrected after hosted PostgreSQL identified fixture-selection and dependent-destroy defects.
