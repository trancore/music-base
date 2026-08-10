import { defineConfig } from 'vitepress'

const repoName = process.env.GITHUB_REPOSITORY?.split('/')[1]
const base = process.env.DOCS_BASE || (process.env.GITHUB_ACTIONS && repoName ? `/${repoName}/` : '/')

export default defineConfig({
  title: 'Music Base',
  description: 'A Windows-first music player for SMB libraries',
  base,
  cleanUrls: true,
  lastUpdated: true,
  locales: {
    root: { label: '日本語', lang: 'ja' },
    en: { label: 'English', lang: 'en' },
  },
  themeConfig: {
    search: { provider: 'local' },
    socialLinks: [],
    nav: [
      { text: '日本語', link: '/ja/' },
      { text: 'English', link: '/en/' },
    ],
    sidebar: {
      '/ja/': [
        {
          text: '利用者向け',
          items: [
            { text: '概要', link: '/ja/user-guide/' },
            { text: 'セットアップ', link: '/ja/user-guide/setup' },
            { text: '音源ライブラリ', link: '/ja/user-guide/library' },
            { text: 'CDリッピング', link: '/ja/user-guide/ripping' },
            { text: '再生と表示', link: '/ja/user-guide/playback' },
            { text: 'トラブルシューティング', link: '/ja/user-guide/troubleshooting' },
          ],
        },
        {
          text: '開発者向け',
          items: [
            { text: '概要', link: '/ja/developer-guide/' },
            { text: '開発環境', link: '/ja/developer-guide/setup' },
            { text: 'アーキテクチャ', link: '/ja/developer-guide/architecture' },
            { text: 'テスト', link: '/ja/developer-guide/testing' },
          ],
        },
      ],
      '/en/': [
        {
          text: 'User guide',
          items: [
            { text: 'Overview', link: '/en/user-guide/' },
            { text: 'Setup', link: '/en/user-guide/setup' },
            { text: 'Music library', link: '/en/user-guide/library' },
            { text: 'CD ripping', link: '/en/user-guide/ripping' },
            { text: 'Playback and display', link: '/en/user-guide/playback' },
            { text: 'Troubleshooting', link: '/en/user-guide/troubleshooting' },
          ],
        },
        {
          text: 'Developer guide',
          items: [
            { text: 'Overview', link: '/en/developer-guide/' },
            { text: 'Development setup', link: '/en/developer-guide/setup' },
            { text: 'Architecture', link: '/en/developer-guide/architecture' },
            { text: 'Testing', link: '/en/developer-guide/testing' },
          ],
        },
      ],
    },
  },
})
