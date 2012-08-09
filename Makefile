test:
	mocha --colors --require should --reporter spec --compilers coffee:coffee-script

watch:
	coffee --watch --lint --output public/javascripts --compile src/

start:
	nodemon app.coffee

.PHONY: test