desc "Tweet"

task :tweet => :environment do
  # Don't tweet if it's late, adjusted for Heroku time 4 hours ahead
  # if Time.now.hour >= 12
    already_knock_knocked_tweet_ids = []
    already_random_word_tweet_ids   = []
    already_snoop_dogged_tweet_ids  = []

    # Collect the user's most recent 30 tweets and add the ids to an exclusion array
    $client.user_timeline.first(30).each do |tweet|
      if tweet.text.include?('Knock knock')
        already_knock_knocked_tweet_ids << tweet.in_reply_to_status_id
      elsif !tweet.text.include?('Snoop Dogg')
        already_random_word_tweet_ids << tweet.in_reply_to_status_id
      elsif tweet.text.include?('Snoop Dogg')
        already_snoop_dogged_tweet_ids << tweet.in_reply_to_status_id
      end
    end
    # Below is for production

    # knock_knock_tweet = $client.search("knock OR knocks OR knocking OR knocked", result_type: "recent").take(5).detect { |tw| tw.retweeted_status.nil? && !already_knock_knocked_tweet_ids.include?(tw.id) }

    # Use this tweet for testing
    knock_knock_tweet = $client.status(636390214617972736) if !already_knock_knocked_tweet_ids.include?($client.status(636390214617972736).id)

    if knock_knock_tweet
      puts "Tweeting to @#{knock_knock_tweet.user.screen_name} in reply to #{knock_knock_tweet.id}..."
      $client.update("@#{knock_knock_tweet.user.screen_name} Knock knock", {in_reply_to_status_id: knock_knock_tweet.id})
    else
      puts "No knock knock-provoking tweet was found, no tweet was sent."
    end

    knock_tweets = []
    snoop_tweets = []

    # mentions_timeline returns an array of the most recent 20 mentions
    $client.mentions_timeline.each do |mention|
      if mention.in_reply_to_screen_name == 'wonderfuljokes'
        if mention.text.include?('ther') && !already_random_word_tweet_ids.include?(mention.id)
          knock_tweets << mention
        elsif mention.text.include?('who') && !mention.text.include?('ther') && !already_snoop_dogged_tweet_ids.include?(mention.id)
          snoop_tweets << mention
        end
      end
    end

    knock_tweets.each do |tweet|
      puts "Tweeting a random word to @#{tweet.user.screen_name} in reply to #{tweet.id}..."
      $client.update("@#{tweet.user.screen_name} bazanba", {in_reply_to_status_id: tweet.id})
    end

    snoop_tweets.each do |tweet|
      puts "Tweeting snoop facts to @#{tweet.user.screen_name} in reply to #{tweet.id}..."
      $client.update("@#{tweet.user.screen_name} Snoop Dogg had a hit record in 1997", {in_reply_to_status_id: tweet.id})
    end
  # end
end
