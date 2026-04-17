#!/usr/bin/env node
// youragent is now published as `agentize` — this shim forwards to it.
const { spawnSync } = require('child_process');
const path = require('path');

process.stderr.write('\x1b[2mheads up: `youragent` is now `agentize` — same package, same code. `npx agentize` going forward.\x1b[0m\n');

const agentizePkg = require.resolve('agentize/package.json');
const installSh = path.join(path.dirname(agentizePkg), 'install.sh');

const result = spawnSync('bash', [installSh, ...process.argv.slice(2)], { stdio: 'inherit' });
process.exit(result.status == null ? 1 : result.status);
