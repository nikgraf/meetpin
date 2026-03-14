import type { ConfigContext, ExpoConfig } from 'expo/config';

type AppVariant = 'development' | 'preview' | 'production';
type EnvMap = Record<string, string | undefined>;

const env = (globalThis as { process?: { env?: EnvMap } }).process?.env ?? {};

function getAppVariant(value: string | undefined): AppVariant {
  if (
    value === 'development' ||
    value === 'preview' ||
    value === 'production'
  ) {
    return value;
  }

  return 'production';
}

function getVariantLabel(variant: AppVariant) {
  switch (variant) {
    case 'development':
      return 'Dev';
    case 'preview':
      return 'Preview';
    case 'production':
      return '';
  }
}

function getVersionCode(value: string | undefined, fallback: number) {
  const parsed = Number.parseInt(value ?? '', 10);
  return Number.isFinite(parsed) ? parsed : fallback;
}

export default ({ config }: ConfigContext): ExpoConfig => {
  const appVariant = getAppVariant(env.APP_VARIANT);
  const isProduction = appVariant === 'production';
  const variantLabel = getVariantLabel(appVariant);
  const baseName = 'meetpin';
  const baseSlug = 'meetpin';
  const baseScheme = 'meetpin';
  const baseBundleIdentifier =
    env.APP_BASE_BUNDLE_IDENTIFIER ?? 'com.nikgraf.meetpin';
  const defaultBundleIdentifier = isProduction
    ? baseBundleIdentifier
    : `${baseBundleIdentifier}.${appVariant}`;
  const version = env.APP_VERSION ?? config.version ?? '1.0.0';
  const projectId = env.EAS_PROJECT_ID;

  return {
    ...config,
    name:
      env.APP_NAME ??
      (isProduction ? baseName : `${baseName} (${variantLabel})`),
    slug: env.APP_SLUG ?? baseSlug,
    version,
    orientation: 'portrait',
    icon: './assets/images/icon.png',
    scheme:
      env.APP_SCHEME ??
      (isProduction ? baseScheme : `${baseScheme}-${appVariant}`),
    userInterfaceStyle: 'automatic',
    runtimeVersion: {
      policy: 'appVersion',
    },
    ios: {
      bundleIdentifier: env.IOS_BUNDLE_IDENTIFIER ?? defaultBundleIdentifier,
      buildNumber: env.IOS_BUILD_NUMBER ?? '1',
      icon: './assets/expo.icon',
    },
    android: {
      package: env.ANDROID_APPLICATION_ID ?? defaultBundleIdentifier,
      versionCode: getVersionCode(env.ANDROID_VERSION_CODE, 1),
      adaptiveIcon: {
        backgroundColor: '#E6F4FE',
        foregroundImage: './assets/images/android-icon-foreground.png',
        backgroundImage: './assets/images/android-icon-background.png',
        monochromeImage: './assets/images/android-icon-monochrome.png',
      },
      predictiveBackGestureEnabled: false,
    },
    web: {
      output: 'static',
      favicon: './assets/images/favicon.png',
    },
    plugins: [
      'expo-router',
      [
        'expo-splash-screen',
        {
          backgroundColor: '#208AEF',
          android: {
            image: './assets/images/splash-icon.png',
            imageWidth: 76,
          },
        },
      ],
    ],
    experiments: {
      typedRoutes: true,
      reactCompiler: true,
    },
    extra: {
      appVariant,
      apiUrl: env.EXPO_PUBLIC_API_URL ?? 'http://localhost:3000',
      ...(projectId
        ? {
            eas: {
              projectId,
            },
          }
        : {}),
    },
  };
};
