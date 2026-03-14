import { renderHook } from '@testing-library/react-native';

import { Colors } from '@/constants/theme';
import { useColorScheme } from '@/hooks/use-color-scheme';
import { useTheme } from '@/hooks/use-theme';

jest.mock('@/hooks/use-color-scheme', () => ({
  useColorScheme: jest.fn(),
}));

const mockedUseColorScheme = jest.mocked(useColorScheme);

describe('useTheme', () => {
  afterEach(() => {
    mockedUseColorScheme.mockReset();
  });

  it('returns the light palette for an unspecified color scheme', () => {
    mockedUseColorScheme.mockReturnValue('unspecified');

    const { result } = renderHook(() => useTheme());

    expect(result.current).toEqual(Colors.light);
  });

  it('returns the dark palette for a dark color scheme', () => {
    mockedUseColorScheme.mockReturnValue('dark');

    const { result } = renderHook(() => useTheme());

    expect(result.current).toEqual(Colors.dark);
  });
});
