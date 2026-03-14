const { defineConfig, globalIgnores } = require('eslint/config');
const expoConfig = require('eslint-config-expo/flat');
const prettierRecommended = require('eslint-plugin-prettier/recommended');
const globals = require('globals');

module.exports = defineConfig([
  globalIgnores([
    '.expo/**',
    'apps/mobile/.expo/**',
    'apps/mobile/expo-env.d.ts',
    'apps/mobile/dist/**',
    'apps/mobile/src/uniwind-types.d.ts',
    'coverage/**',
    'dist/**',
    'node_modules/**',
  ]),
  expoConfig,
  prettierRecommended,
  {
    files: [
      '**/*.config.{js,cjs,mjs}',
      '.github/**/*.js',
      'apps/mobile/scripts/**/*.js',
      'jest.setup.js',
      'test/**/*.cjs',
    ],
    languageOptions: {
      globals: {
        ...globals.node,
      },
    },
  },
  {
    rules: {
      'import/no-unresolved': 'off',
      'prettier/prettier': [
        'error',
        {
          singleQuote: true,
          trailingComma: 'all',
        },
      ],
    },
  },
]);
