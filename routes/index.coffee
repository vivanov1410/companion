exports.index = (req, res) ->
  if req.loggedIn
    user = req.session.auth.twitter.user.screen_name
    user_image = req.session.auth.twitter.user.profile_image_url

  res.render "index",
    title: "Yosh!"
    user: user
    user_image: user_image
