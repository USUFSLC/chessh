# CheSSH

CheSSH is a distributed multiplayer implementation of the game of Chess over SSH, 
written in Elixir, with Discord integrations to deliver alerts when players are 
looking for opponents, or in games when it is a player's turn.

## Usage

### Dependencies
+ `npm`
+ `elixir`
+ `postgresql`
+ `redis` (which you can ignore if you only use the ETS backend for Hammer for 
  `config/dev.exs`)

### Installation

Do something among the lines of:

```
git clone https://github.com/Simponic/chessh
cd chessh

cp .env.example .env
chmod 0700 .env

# In one shell (after filling in your .env), start CheSSH
export $(cat .env | xargs)
mix ecto.create
mix ecto.migrate
iex -S mix

# In another shell, start the frontend
export $(cat .env | xargs)
cd front
npm install
npm start
```

### Environment Variables (mostly optional)
+ `REACT_APP_DISCORD_INVITE` is the invite link to the discord server with the 
  CheSSH bot
+ `REACT_APP_DISCORD_OAUTH` is the link (after replacing the GET params) that will 
  be used to start OAUTH from the frontend
+ `CLIENT_REDIRECT_AFTER_OAUTH` & `SERVER_REDIRECT_URI` are self-explanatory
+ `REACT_APP_SSH_SERVER` and `REACT_APP_SSH_PORT` are used to build the .ssh config
  given to users on the home page of CheSSH after authentication
+ `NEW_GAME_PINGABLE_ROLE_ID` is the role id of the role to ping when a player is
  looking for an opponent
+ `REMIND_MOVE_CHANNEL_ID` is the channel id to create private threads with players
  for move reminders and other communications
+ `NEW_GAME_CHANNEL_ID` is similar to the above

## Architecture
The process of building the pi cluster is wholly contained in the awful 
~buildscripts~, which will individually ~ssh~ into separate pi's and build the 
services locally as well as update the load balancer pi's configurations for nginx 
and HAproxy.

More brief architecture talk of CheSSH can be in my (albeit kinda cringe) FSLC 
presentation on Elixir:
[https://github.com/Simponic/chessh/blob/main/presentation/chessh.org](https://github.com/Simponic/chessh/blob/main/presentation/chessh.org)
