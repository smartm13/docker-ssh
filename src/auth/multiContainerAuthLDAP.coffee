bunyan  = require 'bunyan'
log     = bunyan.createLogger name: 'multiContainerAuthLDAP'
env     = require '../env'
child_process = require('child_process')

ldap_check = (user, pass) -> `child_process.spawnSync('python', [ 'amdocs_ldap.py', user, pass ], { timeout: 5000 }).stdout.toString() != 'Failed\n'`

#
module.exports = (session) ->
  # return function
  f = (ctx) ->
    if ctx.method is 'password'
      if ldap_check(ctx.username, ctx.password)
        log.info {user: ctx.username}, 'Authentication succeeded'

        # set user to session
        session.sessdata.username = ctx.username
        session.sessdata.container = 'env_'+ctx.username

        log.info {s: session.sessdata}, 'Set data to session'

        return ctx.accept()
      else
        log.warn {user: ctx.username, password: ctx.password}, 'Authentication failed'
    ctx.reject(['password'])


  #
  return f
