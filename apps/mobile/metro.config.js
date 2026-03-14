import { getDefaultConfig } from 'expo/metro-config.js';
import { withUniwindConfig } from 'uniwind/metro';
import { dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const projectRoot = dirname(fileURLToPath(import.meta.url));
const config = getDefaultConfig(projectRoot);

export default withUniwindConfig(config, {
  cssEntryFile: './src/global.css',
  dtsFile: './src/uniwind-types.d.ts',
});
