# Miscellaneous notes for developers

## Code coverage on PRs

On PRs, you may notice that the Codecov status reports only 99% code coverage, which will show up as a red X :x: because we want to maintain 100% code coverage on master.

Don't worry about the 99% on PRs. This is just because PRs only run the unit tests (they don't run the integration tests). The code coverage will be 99% with only unit tests, but it will rise to 100% for unit tests + integration tests. So you can still add the PR to the merge queue, and then the integration tests will run in the merge queue, and will increase the code coverage to 100%.
