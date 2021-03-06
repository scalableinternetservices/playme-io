require 'json'

class LobbiesController < ApplicationController
  def index
    @lobbies = Lobby.all
  end
  def new
    @lobby = Lobby.new
  end
  def create
    @lobby = Lobby.new(lobby_params)
    @lobby.state = "in_lobby"
    if @lobby.save
      redirect_to action: "join",id:@lobby.name
      # redirect_to controller: 'lobbies', action: "status"

    else
      render html: "lobby already exists"
    end
  end
  def show
    @lobby = Lobby.find_by(name: params[:id])
    if @lobby.nil?
      print "RECORD NOT FOUND"
      raise ActiveRecord::RecordNotFound
    end
    username = params[:username]
    if session_activated?
      if !(@lobby.sessions.include? current_session)
        deactivate_session
        create_session(username)
      end
    else
      create_session(username)
    end
  end
  def join
    @lobby = Lobby.find_by(name: params[:id])
  end

  def status
    @lobby = Lobby.find_by(name: params[:lobby_id])
    print params
    if @lobby.nil?
      raise ActiveRecord::RecordNotFound
    end
    lobby_hash = {:name => @lobby.name, :sessions => @lobby.sessions}
    render :json => lobby_hash
  end

  def destroy
    deactivate_session
    redirect_to root_url
  end

  def create_session(username)
    session = @lobby.sessions.build
    player_index = get_next_player_index
    if player_index == -1
      # if lobby has 4 players already, raise error
      raise Exceptions::LobbyFullException.new(@lobby.name)
    end
    session.player_index = player_index
    session.readystate = "not_ready"
    session.username = username
    session.save
    activate_session session
    # assign first player to be the leader of the lobby
    if @lobby.leader_id.nil?
      @lobby.leader_id = session.id
      @lobby.save
    end
  end

  def players_json
    players_hash = {}
    @lobby.sessions.each do |session|
      players_hash[session.id] = {}
      players_hash[session.id]["username"] = session.username
      players_hash[session.id]["readystate"] = session.readystate
      players_hash[session.id]["playerIndex"] = session.player_index
    end
    return players_hash.to_json
  end
  helper_method :players_json

  private

  def get_next_player_index
    indices = []
    @lobby.sessions.each do |session|
      indices.push session.player_index
    end
    for i in 0..3 do
      return i unless indices.include?(i)
    end
    return -1
  end

  def lobby_params
    params.require(:lobby).permit(:name)
  end


end
