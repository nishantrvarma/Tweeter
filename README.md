# Hello

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  * Install Node.js dependencies with `cd assets && npm install`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](http://www.phoenixframework.org/docs/deployment).

## Learn more

  * Official website: http://www.phoenixframework.org/
  * Guides: http://phoenixframework.org/docs/overview
  * Docs: https://hexdocs.pm/phoenix
  * Mailing list: http://groups.google.com/group/phoenix-talk
  * Source: https://github.com/phoenixframework/phoenix
  
  # Introduction
  
Twitter is a social network platform that consists of an ecosystem of users that follow one another. Each user has a capability to 'Tweet' a message which broadcasts the particular message to all of his followers. Users that follow a particular user that issues a tweet will see the tweet on his timeline. A tweet consists of a simple message that can contain hashtags (terms prepended with a #) and can mention other users (prepending tweet with an @user). Each user can 'retweet' a particular tweet from another user, which sends the tweet out to the retweeting user's followers. Twitter allows querying the tweets subscribed to, tweets with specific hashtags and tweets in which the user is mentioned (my mentions). On logging out and logging back in, the user must be able to see the relevant tweets. 

# Working
In the project, I simulated a simple twitter application that allows clients to register with a server and start tweeting. When a client logs in, its credentials are checked and if it does not exist, the client is allowed to register with a new password and added to a list of users. If the client exists, the credentials are checked with a database and access to the server is granted if the client is authenticated.
Each client can follow other clients and tweets sent from followed clients are displayed on the current client's output console. Each client can also retweet tweets from other users to its followers. 
I provide capability to query tweets based on hashtags or mentions by using a numbering scheme. Tweets are generated as random texts and are either provided number 0, 1 or 2. If the number is 0, the tweet is to be tweeted out as a normal tweet. If it is number 1, it contains a hashtag and if it is number 2, it contains a mention to a particular client. 
A zipf distribution between clients is obtained in our follow scheme. Each client is followed by every other client ahead of it sequentially in terms of client ID. For instance, For a number of N clients, client 5 will be followed by clients 6,7,8 upto N. Thus clients earlier in the series will have a lot more followers and these clients will produce more tweets in the output while clients with few followed will hardly tweet.
I stress tested the application by sending tweets from each user at an interval of every 1 millisecond.

# Performance
Max number of users : 
We managed to run the simulation with a max of 10,000 users. However this simulation had to be run for 50-60 minutes and thus takes a  very long time. 
CPU Utilization : 
For a 4 core system, during tweeting time, we had 100% utilization of each core.  

Simulation execution times:

      1000 users - 19.5 seconds tweet time - 38 seconds total execution time
      25666 tweets per second

      1500 users - 1 minute 3 seconds tweet time - 2 minutes 59 seconds total execution time
      17869 tweets per second

      2000 users - 2 minute 33 seconds tweet time - 4 minute 27 seconds total execution time
      13340 tweets per second

      10000 users - 26 minute 34 seconds tweet time - 56 minutes 47 seconds
      total execution time
      12270 tweets per second
      
      



