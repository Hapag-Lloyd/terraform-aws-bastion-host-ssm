module.exports = {
  plugins: [
    [
      '@semantic-release/commit-analyzer',
      {
        parserOpts: {
          noteKeywords: ['BREAKING CHANGE', 'BREAKING CHANGES', 'BREAKING'],
        },
        preset: 'angular',
        releaseRules: [
          { type: 'chore', release: 'patch' },
          { type: 'refactor', release: 'patch' },
          { type: 'style', release: 'patch' },
        ],
      },
    ],
    [
      '@semantic-release/release-notes-generator',
      {
        parserOpts: {
          noteKeywords: ['BREAKING CHANGE', 'BREAKING CHANGES', 'BREAKING'],
        },
        preset: 'conventionalcommits',
        presetConfig: {
          types: [
            { type: 'build', section: 'Build System', hidden: false },
            { type: 'chore', section: 'Build System', hidden: false },
            { type: 'ci', section: 'Continuous Integration', hidden: false },
            { type: 'docs', section: 'Documentation', hidden: false },
            { type: 'feat', section: 'Features', hidden: false },
            { type: 'fix', section: 'Bug Fixes', hidden: false },
            { type: 'perf', section: 'Performance Improvements', hidden: false },
            { type: 'refactor', section: 'Code Refactoring', hidden: false },
            { type: 'style', section: 'Styles', hidden: false },
            { type: 'test', section: 'Tests', hidden: false },
          ],
        },
        writerOpts: {
          commitsSort: ['subject', 'scope'],
        },
      },
    ],
  ],
};
