desc "Tweet"

task :knock_knock => :environment do
  # if someone tweets with keywords knock, knocks, knocking, knocked
  knock_knock_tweet = $client.search("knock OR knocks OR knocking OR knocked", result_type: "recent").take(5).detect { |tw| tw.retweeted_status.nil? }
  if knock_knock_tweet
    # tweet 'Knock Knock' to them
    puts "Tweeting to @#{knock_knock_tweet.user.screen_name} in reply to #{knock_knock_tweet.id}..."
    # $client.update("@#{knock_knock_tweet.user.screen_name} Knock knock", {in_reply_to_status_id: knock_knock_tweet.id})
  else
    puts "No knock knock-provoking tweet was found, no tweet was sent."
  end
end

task :handle_replies => :environment do

  # find mentions in the last 10 minutes
    # if someone tweeted at the bot with 'who's there'?
      # do a regex for who there
      # tweet a random word at them
      # want to tweet a noun, look at mw api for nouns
      # dump the random word into
      # tweet a random noun at them

    # if someone tweeted at the bot with 'whatever who?' response that is a reply to a tweet from the bot
      # tweet 'Snoop Dogg had a hit record in 1997' to them
end
