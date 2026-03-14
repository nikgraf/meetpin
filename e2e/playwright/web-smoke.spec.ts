import { expect, test } from '@playwright/test';

test('home and explore navigation work on web', async ({ page }) => {
  await page.goto('/');

  await expect(page.getByTestId('home-title')).toBeVisible();

  await page.getByTestId('tab-explore').click();
  await expect(page).toHaveURL(/\/explore$/);
  await expect(page.getByTestId('explore-title')).toBeVisible();

  await page.getByTestId('tab-home').click();
  await expect(page).toHaveURL(/\/$/);
  await expect(page.getByTestId('home-title')).toBeVisible();
});
