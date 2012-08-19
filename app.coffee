express = require 'express'
routes = require './routes'
http = require 'http'
path = require 'path'

logger = require './lib/logger'
cradle = require 'cradle'
nowjs = require 'now'
#RedisStore = require('connect-redis')(express)
#sessionStore = new RedisStore()
flash = require 'connect-flash'
passport = require 'passport'
LocalStrategy = require('passport-local').Strategy

app = express()

passport.serializeUser (user, done) ->
  done null, user.username

passport.deserializeUser (id, done) ->
  find_user_by_username id, (err, user) ->
    done err, user

passport.use new LocalStrategy((username, password, done) ->
  process.nextTick ->
    find_user_by_username username, (err, user) ->
      return done(err) if err
      unless user
        return done(null, false, message: "Unknown user " + username)
      unless user.password is password
        return done(null, false, message: "Invalid password")
      done null, user)

app.configure ->
  app.set 'port', process.env.PORT or 3000
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'jade'
  app.use express.favicon()
  app.use express.logger
    format: '\x1b[1m:method\x1b[0m \x1b[33m:url\x1b[0m :response-time ms'
  #  stream: logger.stream
  app.use express.cookieParser()
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.session
    secret: 'secret cat'
    cookie:
      maxAge: 60000
  app.use flash()
  app.use passport.initialize()
  app.use passport.session()
  app.use app.router
  app.use require('stylus').middleware(src: __dirname + '/views', dest: __dirname + '/public')
  app.use express.static __dirname + '/public'

app.configure 'development', ->
  app.use express.errorHandler()
  app.set 'db_uri', 'localhost:5984'
  app.set 'db_name', 'companion'

app.configure 'production', ->
    app.use express.errorHandler()
    app.set 'db_uri', 'http://exilium.iriscouch.com'
    app.set 'db_name', 'companion'

# DB Connection
conn = new cradle.Connection app.set 'db_uri'
db = conn.database app.set 'db_name'

app.get '/', (req, res) ->
  if app.settings.env is 'development'
    user =
      id: 'slava'
      username: 'slava'
    req.logIn user, (err) ->
      res.render 'index', user: req.user

app.get '/login', (req, res) ->
  res.render 'login', user: req.user, message: req.flash('error')

app.post '/login',
  passport.authenticate('local', {failureRedirect: '/login', failureFlash: true}),
  (req, res) ->
    res.redirect '/'

app.get '/register', (req, res) ->
  res.render 'register', user: req.user, message: req.flash('error')

app.post '/register', (req, res, next) ->
  data = req.body
  db.get data.username, (err, doc) ->
      if doc
        res.render 'register', message: 'Username is in use', user: req.user
      else
        if data.password isnt data.confirm_password
          res.render 'register', message: 'Password does not match', user: req.user
        else
          delete data.confirm_password;
          db.save data.username
            type: 'user'
            meta: data
          , (db_err, db_res) ->
            user = data
            user['id'] = data.username
            req.logIn user, (err) ->
              res.redirect '/'

app.get '/logout', (req, res) ->
  req.logout();
  res.redirect '/'

app.get '/expenses', (req, res) ->
  db.view 'expenses/all', (err, db_res) ->
    expenses = db_res
    res.render 'expenses', user: req.user, expenses: expenses

app.get '/stops', (req, res) ->
  db.view 'stops/all', (err, db_res) ->
    stops = db_res
    res.render 'stops', user: req.user, stops: stops

app.get '/invoices', (req, res) ->
  db.view 'invoices/all', (err, db_res) ->
    invoices = db_res
    res.render 'invoices', user: req.user, invoices: invoices

http_server = http.createServer(app).listen app.get("port"), ->
  console.log "Express server listening on port " + app.get("port")

everyone = nowjs.initialize(http_server)

everyone.now.submit_expense = (expense) ->
  db.save
    type: 'expense'
    meta: expense
    , (err, res) ->
      db.view 'expenses/all', (err, db_res) ->
        expenses = db_res
        everyone.now.update_expenses expenses

everyone.now.submit_stop = (stop) ->
  db = conn.database app.set 'db_documents'
  db.save stop, (err, res) ->
    db.view 'documents/all_stops', (err, db_res) ->
      stops = db_res
      everyone.now.update_stops stops

find_user_by_username = (username, fn) ->
  db.get username, (err, doc) ->
    fn err, doc.meta

