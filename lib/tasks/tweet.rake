desc "Tweet"

task :tweet => :environment do
  # Don't tweet if it's late, adjusted for Heroku time 4 hours ahead
  # if Time.now.hour >= 12
    compile_already_used_tweet_ids
    tweet_knock_knock
    tweet_words_and_snoop_dog
  # end
end

def compile_already_used_tweet_ids
  @already_knock_knocked_tweet_ids = []
  @already_random_word_tweet_ids   = []
  @already_snoop_dogged_tweet_ids  = []

  # Collect the user's most recent 30 tweets and add the ids to an exclusion array
  $client.user_timeline.first(30).each do |tweet|
    if tweet.text.include?('Knock knock')
      @already_knock_knocked_tweet_ids << tweet.in_reply_to_status_id
    elsif !tweet.text.include?('Snoop Dogg')
      @already_random_word_tweet_ids << tweet.in_reply_to_status_id
    elsif tweet.text.include?('Snoop Dogg')
      @already_snoop_dogged_tweet_ids << tweet.in_reply_to_status_id
    end
  end
end

def tweet_knock_knock
  if knock_knock_tweet
    puts "Tweeting to @#{knock_knock_tweet.user.screen_name} in reply to #{knock_knock_tweet.id}..."
    $client.update("@#{knock_knock_tweet.user.screen_name} Knock knock", {in_reply_to_status_id: knock_knock_tweet.id})
  else
    puts "No knock knock-provoking tweet was found, no tweet was sent."
  end
end

def knock_knock_tweet
  # Below is for production

  # @knock_knock_tweet ||= $client.search("knock OR knocks OR knocking OR knocked", result_type: "recent").take(5).detect { |tw| tw.retweeted_status.nil? && !@already_knock_knocked_tweet_ids.include?(tw.id) }

  # Use this tweet for testing
  @knock_knock_tweet ||= $client.status(636390214617972736) if !@already_knock_knocked_tweet_ids.include?($client.status(636390214617972736).id)
end

def tweet_words_and_snoop_dog
  collect_knock_and_snoop_tweets
  send_random_word_tweet
  send_snoop_tweet
end

def collect_knock_and_snoop_tweets
  @knock_tweets = []
  @snoop_tweets = []

  # mentions_timeline returns an array of the most recent 20 mentions
  $client.mentions_timeline.each do |mention|
    if mention.in_reply_to_screen_name == 'wonderfuljokes'
      if mention.text.include?('ther') && !@already_random_word_tweet_ids.include?(mention.id)
        @knock_tweets << mention
      elsif mention.text.include?('who') && !mention.text.include?('ther') && !@already_snoop_dogged_tweet_ids.include?(mention.id)
        @snoop_tweets << mention
      end
    end
  end
end

def send_random_word_tweet
  @knock_tweets.each do |tweet|
    puts "Tweeting a random word to @#{tweet.user.screen_name} in reply to #{tweet.id}..."

    $client.update("@#{tweet.user.screen_name} #{random_word_from_wordnik}", {in_reply_to_status_id: tweet.id})
  end
end

def send_snoop_tweet
  @snoop_tweets.each do |tweet|
    puts "Tweeting snoop facts to @#{tweet.user.screen_name} in reply to #{tweet.id}..."
    $client.update("@#{tweet.user.screen_name} Snoop Dogg had a hit record in 1997", {in_reply_to_status_id: tweet.id})
  end
end

def random_word_from_wordnik
  # Temp request for a random noun, will replace with API credentials when I get them
  endpoint = 'http://api.wordnik.com:80/v4/words.json/randomWord?hasDictionaryDef=false&includePartOfSpeech=noun&minCorpusCount=0&maxCorpusCount=-1&minDictionaryCount=1&maxDictionaryCount=-1&minLength=5&maxLength=-1&api_key=a2a73e7b926c924fad7001ca3111acd55af2ffabf50eb4ae5'

  word = JSON.parse(Net::HTTP.get(URI.parse(endpoint)))['word']
end