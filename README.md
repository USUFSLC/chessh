# CheSSH

CheSSH is a distributed multiplayer implementation of the game of Chess over SSH, 
written in Elixir, with Discord integrations to deliver alerts when players are 
looking for opponents, or in games when it is one's turn.

https://user-images.githubusercontent.com/25559600/221317658-a80046ca-6009-456d-b43c-67d95baa4bf6.mp4

## Usage

### Dependencies
+ `npm`
+ `elixir`
+ `postgresql`
+ `redis` (which you can ignore if you only use the ETS backend for Hammer in 
  `config/dev.exs` [set by default])

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

## Architecture
The process of building the pi cluster is wholly contained in the awful 
`buildscripts`, which will individually `ssh` into separate pi's and build the 
services locally there as well as update the load balancer pi's configurations for nginx 
and HAproxy.

More architecture talk of CheSSH can be found in my (albeit kinda cringe) FSLC 
presentation on Elixir:
[https://github.com/Simponic/chessh/blob/main/presentation/chessh.org](https://github.com/Simponic/chessh/blob/main/presentation/chessh.org)


## Environment Variables (mostly optional)
+ `REACT_APP_DISCORD_INVITE` is the invite link to the discord server with the 
  CheSSH bot
+ `REACT_APP_DISCORD_OAUTH` is the link (after replacing the GET  URL params) that will 
  be used to initiate discord OAUTH from the frontend
+ `CLIENT_REDIRECT_AFTER_OAUTH` & `SERVER_REDIRECT_URI` are self-explanatory
+ `REACT_APP_SSH_SERVER` and `REACT_APP_SSH_PORT` are used to build the .ssh config
  given to users on the home page of CheSSH after authentication
+ `NEW_GAME_PINGABLE_ROLE_ID` is the role id of the role to ping when one is
  looking for an opponent
+ `REMIND_MOVE_CHANNEL_ID` is the channel id to create private threads with players
  for move reminders and other communications
+ `NEW_GAME_CHANNEL_ID` is similar to the above
