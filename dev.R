# This file serves as a record of key steps and dependencies
# used to create this slide deck. 
# dev.R is not meant to be run as a standalone script; rather,
# it is bibliographic in nature.

# README format borrowed from 
# https://github.com/gadenbuie/drake-intro
# html codes for emojis identified via ermoji
# https://github.com/gadenbuie/ermoji

# basic Rmd structure and logos borrowed from
# https://github.com/tgerke/ci4cc-cdsc

# unicoRn hex logo created by Jordan Creed
# 

# swivel css from
# https://vaibhav111tandon.github.io/vov.css/

# tweet screenshots captured with tweetrmd
# https://github.com/gadenbuie/tweetrmd

if (!fs::file_exists(here::here("figures", "rasgon-tweet.png"))) {
   tweetrmd::tweet_screenshot(
      tweetrmd::tweet_url("vectorgen", "1160180495080202242"),
      maxwidth = 400,
      hide_media = TRUE,
      # theme = "dark",
      file = here::here("figures", "rasgon-tweet.png")
   )
}
