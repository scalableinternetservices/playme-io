class LobbiesController < ApplicationController
  def index
    @lobbies = Lobby.all
  end
  def new
    @lobby = Lobby.new
  end
  def create
    @lobby = Lobby.new(lobby_params)
    if @lobby.save
      redirect_to action: "show",id:@lobby.name
    else
      render html: "couldn't save lobby"
    end
  end
  def show
    @lobby = Lobby.find_by(name: params[:id])
    if @lobby.nil?
      raise ActiveRecord::RecordNotFound
    end
    if session_activated?
      if !(@lobby.sessions.include? current_session)
        deactivate_session
        create_session
      end
    else
      create_session
    end
  end

  def destroy
    deactivate_session
    redirect_to root_url
  end

  def create_session
    session = @lobby.sessions.build
    session.save
    activate_session session
  end


  private

  def lobby_params
    params.require(:lobby).permit(:name)
  end

end
