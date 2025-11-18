#!/usr/bin/env node
import { existsSync, mkdirSync, writeFileSync, chmodSync } from 'fs'
import { fileURLToPath } from 'url'
import { dirname, join } from 'path'

const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)

const huskyDir = join(__dirname)

if (!existsSync(huskyDir)) {
  mkdirSync(huskyDir, { recursive: true })
}

const huskySh = join(huskyDir, '_', 'husky.sh')
if (!existsSync(huskySh)) {
  const huskyShDir = join(huskyDir, '_')
  if (!existsSync(huskyShDir)) {
    mkdirSync(huskyShDir, { recursive: true })
  }
}

console.log('Husky is already set up')

