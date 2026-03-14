import { render, screen } from '@testing-library/react-native';

import { ThemedText } from '@/components/themed-text';
import { Colors } from '@/constants/theme';
import { useColorScheme } from '@/hooks/use-color-scheme';

jest.mock('@/hooks/use-color-scheme', () => ({
  useColorScheme: jest.fn(),
}));

const mockedUseColorScheme = jest.mocked(useColorScheme);

describe('ThemedText', () => {
  afterEach(() => {
    mockedUseColorScheme.mockReset();
  });

  it('renders dark theme colors for title text', () => {
    mockedUseColorScheme.mockReturnValue('dark');

    render(<ThemedText type="title">Meetpin</ThemedText>);

    expect(screen.getByText('Meetpin')).toHaveStyle({
      color: Colors.dark.text,
      fontSize: 48,
      fontWeight: 600,
    });
  });
});
