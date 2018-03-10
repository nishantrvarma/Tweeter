defmodule HelloWeb.RoomChannel do
    use Phoenix.Channel

    IO.puts "vivek"

    def join("room:lobby", _message, socket) do
      {:ok, socket}
    end

    def join("room:" <> _private_room_id, _params, _socket) do
      {:error, %{reason: "unauthorized"}}
    end

    def handle_in("login", %{"login" => loginId, "passwd" => passwd}, socket) do
        listOfTweets = []
        if length(:ets.lookup(:userDetails, loginId)) == 1 do
            if elem(Enum.at(:ets.lookup(:userDetails, loginId),0),1) == passwd do
              followingList = elem(Enum.at(:ets.lookup(:userFollow, loginId),0),2)
              len = length followingList
              :ets.insert(:socketDetails, {loginId, socket.id})
              listOfTweets = ["Welcome back!"] ++ getAllTweetsOfFollowing(followingList, len, listOfTweets)
            else
              listOfTweets = listOfTweets ++ ["Wrong credentials!"]
            end
        else
            :ets.insert_new(:userDetails, {loginId, passwd})
            listOfTweets = listOfTweets ++ ["New Registration Successful"]
            #IO.puts "Successful"
            :ets.insert(:socketDetails, {loginId, socket.id})
            #IO.puts "sako"
            #IO.inspect socket.id
        end
        # render and reply
        push socket, "login", %{"listOfTweets" => listOfTweets}
        {:noreply, socket}
        #{:reply, {:ok, %{listOfTweets: listOfTweets}}, socket} #chane this to reply
    end

    def getAllTweetsOfFollowing(followingList, len, listOfTweets) do
        if len>0 do
            followingId = Enum.at(followingList, len-1)
            # putting all tweets in a list together with tweeter's following id
            listOfTweets = listOfTweets ++ [" User: "<>followingId<>" tweeted: "] ++ elem(Enum.at(:ets.lookup(:userTweets, followingId),0),1)
            listOfTweets = getAllTweetsOfFollowing(followingList, len-1, listOfTweets)
        end
        listOfTweets
    end

    def handle_in("followPeople", %{"login" => loginId, "follow" => loginIdToFollow}, socket) do
        if length(:ets.lookup(:userDetails, loginIdToFollow)) == 1 do
            if length(:ets.lookup(:userFollow, loginId)) == 1 do
                followerList = elem(Enum.at(:ets.lookup(:userFollow, loginId),0),1)
                followingList = elem(Enum.at(:ets.lookup(:userFollow, loginId),0),2) ++ [loginIdToFollow]
                :ets.insert(:userFollow, {loginId, followerList, followingList})
            else
                :ets.insert_new(:userFollow, {loginId, [], [loginIdToFollow]})
            end

            # updating follower list also of the one which is being followed
            if length(:ets.lookup(:userFollow, loginIdToFollow)) == 1 do
                #IO.inspect :ets.lookup(:userFollow, loginIdToFollow)
                #IO.inspect elem(Enum.at(:ets.lookup(:userFollow, loginId),0),1)
                followerList = elem(Enum.at(:ets.lookup(:userFollow, loginIdToFollow),0),1) ++ [loginId]
                #IO.inspect followerList
                followingList = elem(Enum.at(:ets.lookup(:userFollow, loginIdToFollow),0),2)
                :ets.insert(:userFollow, {loginIdToFollow, followerList, followingList})
            else
                :ets.insert_new(:userFollow, {loginIdToFollow, [loginId], []})
            end
        end
        {:noreply, socket}
    end

    def handle_in("tweet", %{"login" => loginId, "tweet" => tweet}, socket) do
        checkHashtagAndMentions(tweet)
        if length(:ets.lookup(:userTweets, loginId)) == 1 do
            tweets = elem(Enum.at(:ets.lookup(:userTweets, loginId),0),1) ++ [tweet]
            :ets.insert(:userTweets, {loginId, tweets})
        else
            :ets.insert_new(:userTweets, {loginId, [tweet]})
        end
        if length(:ets.lookup(:userFollow, loginId)) == 1 do
            followerList = elem(Enum.at(:ets.lookup(:userFollow, loginId),0),1)
            len = length followerList
            IO.puts "trying"
            broadcast! socket, "tweet", %{id: loginId, tweetMsg: tweet, followers: followerList, len: len}
        end
        {:noreply, socket}
    end

    def handle_in("retweet", %{"login" => loginId, "retweet" => retweet}, socket) do  #handling retweet entry
        if length(:ets.lookup(:userFollow, loginId)) == 1 do
            followerList = elem(Enum.at(:ets.lookup(:userFollow, loginId),0),1)
            followingList = elem(Enum.at(:ets.lookup(:userFollow, loginId),0),2) #list of clients being followed by user
            lenNew = length followingList                                        #length of following list
            len = length followerList
            IO.puts "tryingnew"
            broadcast! socket, "retweet", %{id: loginId, retweetMsg: retweet, followers: followerList, following: followingList, len: len, lenNew: lenNew}
        end
        {:noreply, socket}
    end

    def checkHashtagAndMentions(tweet) do #make it handle_cast
        if tweet =~ "#" do
            index = (:binary.match tweet, "#") |> elem(0)
            tag = ""
            tag = generateTagorMention(tweet, index, tag)
            if length(:ets.lookup(:hashtagSearch, tag)) == 1 do
                tweets = elem(Enum.at(:ets.lookup(:hashtagSearch, tag),0),1) ++ [tweet]
                :ets.insert(:hashtagSearch, {tag, tweets})
            else
                :ets.insert_new(:hashtagSearch, {tag, [tweet]})
            end
        end
        if tweet =~ "@" do
            index = (:binary.match tweet, "@") |> elem(0)
            mention = ""
            mention = generateTagorMention(tweet, index, mention)
            if length(:ets.lookup(:mentionSearch, mention)) == 1 do
                tweets = elem(Enum.at(:ets.lookup(:mentionSearch, mention),0),1) ++ [tweet]
                :ets.insert(:mentionSearch, {mention, tweets})
            else
                :ets.insert_new(:mentionSearch, {mention, [tweet]})
            end
        end
    end

    def generateTagorMention(tweet, index, tag) do
        if String.at(tweet, index+1) != " " && String.at(tweet, index+1) != nil do
            tag = tag <> String.at(tweet, index+1)
            tag = generateTagorMention(tweet, index+1, tag)
        end
        tag
    end

    # check from which socket the message came and decide it should be shown or not
    intercept ["tweet", "retweet"]
    def handle_out("tweet", msg, socket) do
        #IO.puts "success"
        followerList = msg.followers
        len = msg.len
        tweet = msg.tweetMsg
        id = msg.id
        searchFollowerOnline(id, followerList, len, tweet, socket)
        #IO.puts "kaise hoga"
        {:noreply, socket}
    end

    #intercept ["retweet"]                       #intercepting the retweets in the channel
    def handle_out("retweet", msg, socket) do
        #IO.puts "success"
        followerList = msg.followers
        len = msg.len
        followingList = msg.following
        lenNew = msg.lenNew
        retweet = msg.retweetMsg
        id = msg.id
        #Find list of clients being followed that are online
        searchFollowingOnline(id, followingList, followerList, lenNew, len, retweet, socket) 
        #IO.puts "kaise hoga"
        {:noreply, socket}
    end

    def searchFollowerOnline(id, followerList, len, tweet, socket) do
        if len>0 do
            followerId = Enum.at(followerList, len-1)
            IO.inspect followerList
            if elem(Enum.at(:ets.lookup(:socketDetails, followerId),0),1) == socket.id do
                #IO.puts "zzzz"
                push socket, "tweet", %{"tweet" => tweet, "id" => id}
                #{:noreply, socket} #doubtful, may need to remove this
            else
                searchFollowerOnline(id, followerList, len-1, tweet, socket)
            end
        end
    end

    #retweeting to followers
    def searchFollowerOnlineNew(id, followingId, followerList, len, retweet, socket) do
        if len>0 do
            followerId = Enum.at(followerList, len-1)
            IO.inspect followerList
            if elem(Enum.at(:ets.lookup(:socketDetails, followerId),0),1) == socket.id do
                #IO.puts "zzzz"
                push socket, "retweet", %{"retweet" => retweet, "id" => id, "followingId" => followingId}
                #{:noreply, socket} #doubtful, may need to remove this
            else
                searchFollowerOnlineNew(id, followingId, followerList, len-1, retweet, socket)
            end
        end
    end

    def searchFollowingOnline(id, followingList, followerList, lenNew, len, retweet, socket) do
        if len>0 do
            followingId = Enum.at(followingList, lenNew-1)
            IO.inspect followingList
            if length(:ets.lookup(:userTweets, followingId)) == 1 do
                #retrieves tweet list of a client being followed
                tweets = elem(Enum.at(:ets.lookup(:userTweets, followingId),0),1) 
                #check if retweet exists in tweet list
                if Enum.member?(tweets, retweet) do
                    #retweet to followers if retweet is valid
                    searchFollowerOnlineNew(id, followingId, followerList, len, retweet, socket)
                else
                    searchFollowingOnline(id, followingList, followerList, lenNew-1, len, retweet, socket)
                end
            end   
        end
    end

    def handle_in("hashtagFind", %{"tag" => hashtag}, socket) do
        tweets = []
        if length(:ets.lookup(:hashtagSearch, hashtag)) == 1 do
            tweets = tweets ++ elem(Enum.at(:ets.lookup(:hashtagSearch, hashtag),0),1)
        else
            tweets = tweets ++ ["0 tweets with this hashtag found"]
        end
        # do rendering
        push socket, "hashtagFind", %{"tweets" => tweets}
        {:noreply, socket}
    end

    def handle_in("mentionFind", %{"tag" => mention}, socket) do
        tweets = []
        if length(:ets.lookup(:mentionSearch, mention)) == 1 do
            tweets = tweets ++ elem(Enum.at(:ets.lookup(:mentionSearch, mention),0),1)
        else
            tweets = tweets ++ ["0 tweets with this mention found"]
        end
        # do rendering
        push socket, "mentionFind", %{"tweets" => tweets}
        {:noreply, socket}
    end
end