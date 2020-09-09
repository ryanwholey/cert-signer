const fs = require('fs')
const childProcess = require('child_process')
const path = require('path')
const axios = require('axios')
const shell = require('shelljs')


const publicKeyPath = path.join(process.env.HOME, '.ssh/id_rsa.pub')
const certFilePath = path.join(process.env.HOME, '.ssh/id_rsa-cert.pub')
const knownHostsPath = path.join(process.env.HOME, '.ssh/known_hosts')

const sshRetryCodes = [255]

const bastionMap = {
  playground: 'bastion.ryanwholey.com',
  staging: 'bastion.ryanwholey.com',
  production: 'bastion.ryanwholey.com',
}

async function findLocalToken({ environment, verbose, role }) {
  const paths = [
    process.env.VAULT_TOKEN_PATH,
    `/tmp/${environment}-${role}-vault-token`,
  ]

  let token
  for (const tokenPath of paths) {
    try {
      token = await fs.promises.readFile(tokenPath, 'utf8')
      if (verbose) {
        console.log(`Token found. Using ${tokenPath}`)
      }
      break
    } catch (err) {
      if (verbose) {
        console.error(`No token found at path ${tokenPath}. Continuing`)
      }
    }
  }
  if (!token && verbose) {
    console.error('No local token found.') 
  }

  return token
}

async function vaultLogin({ addr, role, environment, verbose }) {
  const { stdout, stderr, code } = shell.exec(`vault login -address=${addr} -no-store -token-only -method=oidc role=${role}`, { silent: true })

  if (verbose || code !== 0) {
    console.log(stdout)
    console.error(stderr)
    process.exit(code)
  }

  if (verbose) {
    console.log(`Saving token to /tmp/${environment}-${role}-vault-token`)
  }

  await fs.promises.writeFile(`/tmp/${environment}-${role}-vault-token`, stdout)

  return stdout
}

async function renewToken({addr, token}) {
  return axios.post(`${addr}/v1/auth/token/renew-self`, {}, {
    headers: {'X-Vault-Token': token},
  })
}

async function getToken({ environment, verbose, addr, forceLogin, role }) {
  let token 
  let tokenIsInvalid = false
  if (!forceLogin) {
    token = await findLocalToken({
      environment,
      role,
      verbose,
    })
    
    try {
      const res = await renewToken({ addr, token })
      if (res.status >= 400) {
        throw new Error(res.statusText)
      }
    } catch (error) {
      if (verbose) {
        console.error(error)
      }
      tokenIsInvalid = true
    }
  }

  if (!token ||tokenIsInvalid || forceLogin) {
    token = await vaultLogin({ environment, addr, role, verbose })
  }

  return token
}

async function updateCertAuthority({ environment, addr, token }) {
  const cert = await axios.get(`${addr}/v1/ssh-host-signer/config/ca`, {
    headers: {'X-Vault-Token': token},
  })
  const bastion = bastionMap[environment]

  const certAuthorityPrefix = `@cert-authority ${bastion}`

  try {
      await fs.promises.stat(knownHostsPath)
  } catch (error) {
      await fs.promises.writeFile(knownHostsPath, '')
  }

  const hosts = (await fs.promises.readFile(knownHostsPath, 'utf8'))
    .split('\n')
    .filter(l => !!l)
    .filter(l => !l.startsWith(certAuthorityPrefix))

  hosts.push(`${certAuthorityPrefix} ${cert.data.data.public_key}`)

  await fs.promises.writeFile('/tmp/hosts', hosts.join('\n'))
}
  
async function signClientCert({ addr, role, token }) {
  const res = await axios.post(`${addr}/v1/ssh-client-signer/sign/${role}`, {
    public_key: await fs.promises.readFile(publicKeyPath, 'utf8')
  }, {
    headers: { 'X-Vault-Token': token },
  })
  return res.data.data.signed_key
}

function startSsh(args, options = {}) {
  console.log(...['ssh', ...args])
  return new Promise((resolve, reject) => {
    const ssh = childProcess.spawn('ssh', args, {
      interactive: true,
      stdio: 'inherit',
      ...options,
    })

    ssh.on('exit', (exitCode) => resolve(exitCode))
    ssh.on('error', (err) => reject(err))
  })
}


function formatOpts({
  verbose,
  environment,
  role,
  host,
  localPort,
  remotePort,
  dynamicPort,
}) {

  let opts = []

  if (verbose) {
    opts.unshift('-v')
  }
  
  if (host && host.startsWith('bastion')) {
    opts.push(`${role}@${host}`)
  } else {
    if (dynamicPort) {
      opts = opts.concat(`-N -D ${dynamicPort} ${role}@${bastionMap[environment]}`.split(' '))
    } else if (localPort) {
      opts = opts.concat(`-N -L ${localPort}:${host}:${remotePort} ${role}@${bastionMap[environment]}`.split(' '))
    } else {
      opts = opts.concat(`-J ${role}@${bastionMap[environment]} ${role}@${host}`.split(' '))
    }
  }
  console.log(opts)
  return opts
}



async function main({
  environment,
  verbose,
  addr,
  login: forceLogin,
  role,
  token: vaultToken,
  host,
  localPort,
  remotePort,
  dynamicPort,
}) {
  const vaultAddress = addr || "https://vault.vault-ssh.ryanwholey.com"
  
  const token = vaultToken || await getToken({ environment, verbose, addr: vaultAddress, forceLogin, role })
  
  await updateCertAuthority({ environment, addr: vaultAddress, token }) // remove old cert authorites

  let exitCode
  do {
    const cert = await signClientCert({ addr: vaultAddress, token, role })
    await fs.promises.writeFile(certFilePath, cert)

    exitCode = await startSsh(formatOpts({
      verbose,
      environment,
      role,
      host,
      localPort,
      remotePort,
      dynamicPort,
    }))

    console.log(`exit code: ${exitCode}`)
    
  } while (sshRetryCodes.includes(exitCode))
  
  console.log('goodbye')
}

module.exports = main
