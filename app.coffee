express = require 'express'
routes = require './routes'
http = require 'http'
path = require 'path'

logger = require './lib/logger'
everyauth = require 'everyauth'
cradle = require 'cradle'
nowjs = require 'now'
RedisStore = require('connect-redis')(express)
sessionStore = new RedisStore()

everyauth.debug = true

app = express()

usersByLogin =
  'slava':
    login: 'slava'
    email: 'slava.eth@gmail.com'
    password: '123'

fuel_receipts =
  '1':
    date: new Date().toLocaleDateString()
    country: 'Canada'
    state: 'BC'
    quantity: '100'
    points: 'L'
  '2':
    date: new Date().toLocaleDateString()
    country: 'USA'
    state: 'WA'
    quantity: '50'
    points: 'Gal'

everyauth.password
  .loginWith('login')
  .getLoginPath('/login')
  .postLoginPath('/login')
  .loginView('login.jade')
  .loginLocals (req, res, done) ->
    setTimeout ->
      done null, title: 'Async login'
    , 200
  .authenticate (login, password) ->
    errors = []
    errors.push 'Missing login' unless login
    errors.push 'Missing password' unless password
    return errors if errors.length
    user = usersByLogin[login]
    return ['Login failed'] unless user
    return ['Login failed'] if user.password isnt password
    user
  .getRegisterPath('/register')
  .postRegisterPath('/register')
  .registerView('register.jade')
  .registerLocals (req, res, done) ->
    setTimeout ->
      done null, title: 'Async Register'
    , 200
  .extractExtraRegistrationParams (req) ->
    email: req.body.email
  .validateRegistration (newUserAttrs, errors) ->
    login = newUserAttrs.login
    errors.push "Login already taken" if usersByLogin[login]
    errors
  .registerUser (newUserAttrs) ->
    login = newUserAttrs[@loginKey()]
    usersByLogin[login] = newUserAttrs
  .loginSuccessRedirect('/')
  .registerSuccessRedirect('/')

everyauth.everymodule.findUserById (userId, callback) ->
   console.log "user id is #{userId}"
   callback null, userId: userId

app.configure ->
  app.set "port", process.env.PORT or 3000
  app.set "views", __dirname + "/views"
  app.set "view engine", "jade"
  app.use express.favicon()
  app.use express.logger { format: '\x1b[1m:method\x1b[0m \x1b[33m:url\x1b[0m :response-time ms', stream: logger.stream }
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.cookieParser('your secret here')
  app.use express.session
    secret: 'MYSECRETKEY'
    store: sessionStore
  app.use everyauth.middleware(app)
  app.use app.router
  app.use require("stylus").middleware(src: __dirname + '/views', dest: __dirname + '/public')
  app.use express.static __dirname + '/public'

app.configure "development", ->
  app.use express.errorHandler()
  app.set 'db-uri', 'localhost:5984'
  app.set 'db-users', 'cn_users'

app.configure 'production', ->
    app.use express.errorHandler()
    app.set 'db-uri', 'http://exilium.iriscouch.com'
    app.set 'db-name', 'yo_users'

# DB Connection
conn = new cradle.Connection app.set 'db-uri'
db = conn.database app.set 'db-users'

app.get '/', (req, res) ->
  if req.loggedIn
    res.render 'index', title: 'Companion'
  else
    res.redirect 'login'

app.get '/fuel', (req, res) ->
  res.render 'fuel',
    title: 'Companion.Fuel'
    fuel_receipts: fuel_receipts

http_server = http.createServer(app).listen app.get("port"), ->
  console.log "Express server listening on port " + app.get("port")

everyone = nowjs.initialize(http_server)

