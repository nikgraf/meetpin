export default {
  preset: 'jest-expo',
  rootDir: '.',
  testMatch: [
    '<rootDir>/apps/mobile/src/**/__tests__/**/*.(test|spec).tsx',
    '<rootDir>/apps/mobile/src/**/__tests__/**/*.(test|spec).ts',
    '<rootDir>/apps/mobile/src/**/*.(test|spec).tsx',
    '<rootDir>/apps/mobile/src/**/*.(test|spec).ts',
  ],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/apps/mobile/src/$1',
    '^@/assets/(.*)$': '<rootDir>/apps/mobile/assets/$1',
    '\\.css$': '<rootDir>/test/style-mock.js',
  },
};
