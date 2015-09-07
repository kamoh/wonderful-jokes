require_relative '../helpers/snoop_facts'

desc "Tweet"

task :tweet_wonderful_jokes => :environment do
  # Don't tweet if it's late, adjusted for Heroku time 4 hours ahead
  # if Time.now.hour >= 12
    compile_already_used_tweet_ids
    tweet_knock_knock
    tweet_words_and_snoop_dog
  # end
end

# Tweets older than the last 30 tweets so it doesn't tweet at old people again

def compile_already_used_tweet_ids
  @already_knock_knocked_screen_names = []
  @already_random_word_screen_names   = []
  @already_snoop_dogged_screen_names  = []

  # Collect the bot's most recent 30 tweets and add the screen names tweeted at to an exclusion array
  $client.user_timeline.first(30).each do |tweet|
    if tweet.text.include?('Knock knock')
      @already_knock_knocked_screen_names << tweet.in_reply_to_screen_name
    elsif !tweet.text.include?('Snoop Dogg')
      @already_random_word_screen_names << tweet.in_reply_to_screen_name
    elsif tweet.text.include?('Snoop Dogg')
      @already_snoop_dogged_screen_names << tweet.in_reply_to_screen_name
    end
  end
end

def tweet_knock_knock
  if knock_knock_tweet
    puts "Tweeting knock knock to @#{knock_knock_tweet.user.screen_name} in reply to #{knock_knock_tweet.id}..."
    $client.update("@#{knock_knock_tweet.user.screen_name} Knock knock", {in_reply_to_status_id: knock_knock_tweet.id})
  else
    puts "No knock knock-provoking tweet was found, no tweet was sent."
  end
end

def knock_knock_tweet
  # Use this for production

  @knock_knock_tweet ||= $client.search("knock OR knocks OR knocking OR knocked", result_type: "recent").take(5).detect do |tw|
      tw.retweeted_status.nil? && !@already_knock_knocked_screen_names.include?(tw.user.screen_name)
    end

  # Use this designated tweet for testing

  # @knock_knock_tweet ||= $client.status(636390214617972736) if !@already_knock_knocked_screen_names.include?($client.status(636390214617972736).user.screen_name)
end

def tweet_words_and_snoop_dog
  collect_knock_and_snoop_tweets
  send_random_word_tweet
  send_snoop_tweet
end

def collect_knock_and_snoop_tweets
  @word_tweets  = []
  @snoop_tweets = []
  today = Time.now
  # mentions_timeline returns an array of the most recent 20 mentions
  $client.mentions_timeline.each do |mention|
    # Is the below line redundant? Aren't mentions_timelines tweets going to be mentions related to the bot account?
    # Only reply to mentions created since the last check to prevent over-tweeting
    if mention.created_at > today - 10.minutes # && mention.in_reply_to_screen_name == 'wonderfuljokes'
      if mention.text.downcase.include?('ther') && !@already_random_word_screen_names.include?(mention.user.screen_name)
        @word_tweets << mention
      elsif mention.text.downcase.include?('who') && !mention.text.downcase.include?('ther') && !@already_snoop_dogged_screen_names.include?(mention.user.screen_name)
        @snoop_tweets << mention
      end
    end
  end
end

def send_random_word_tweet
  @word_tweets.each do |tweet|
    puts "Tweeting a random word to @#{tweet.user.screen_name} in reply to #{tweet.id}..."

    $client.update("@#{tweet.user.screen_name} #{random_word_from_wordnik}", {in_reply_to_status_id: tweet.id})
  end
end

def send_snoop_tweet
  @snoop_tweets.each do |tweet|
    puts "Tweeting snoop facts to @#{tweet.user.screen_name} in reply to #{tweet.id}..."
    $client.update("@#{tweet.user.screen_name} #{SNOOP_FACTS.sample}", {in_reply_to_status_id: tweet.id})
  end
end

def random_word_from_wordnik
  # Temp request for a random noun, will replace with API credentials when I get them
  endpoint = 'http://api.wordnik.com:80/v4/words.json/randomWord?hasDictionaryDef=false&includePartOfSpeech=noun&minCorpusCount=0&maxCorpusCount=-1&minDictionaryCount=1&maxDictionaryCount=-1&minLength=5&maxLength=-1&api_key=a2a73e7b926c924fad7001ca3111acd55af2ffabf50eb4ae5'

  response = Net::HTTP.get(URI.parse(endpoint))
  word = JSON.parse(response)['word']
  word.capitalize
end
