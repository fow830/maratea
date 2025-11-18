/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  env: {
    API_URL: process.env.API_URL || 'http://localhost:8080',
    LANDING_URL: process.env.LANDING_URL || 'http://localhost:3001',
  },
}

module.exports = nextConfig

