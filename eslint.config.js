import { defineConfig, globalIgnores } from 'eslint/config';
import expoConfig from 'eslint-config-expo/flat.js';
import prettierRecommended from 'eslint-plugin-prettier/recommended';
import globals from 'globals';

export default defineConfig([
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
      '**/*.config.{js,mjs}',
      '.github/**/*.js',
      'apps/mobile/scripts/**/*.js',
      'test/**/*.js',
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
