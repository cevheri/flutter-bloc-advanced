import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  timeout: 60000,
  retries: 0,
  use: {
    baseURL: 'http://localhost:9090',
    headless: true,
    screenshot: 'on',
    trace: 'on-first-retry',
    viewport: { width: 1440, height: 900 },
  },
  outputDir: '../test_results',
  reporter: [
    ['list'],
    ['json', { outputFile: '../test_results/results.json' }],
  ],
});
