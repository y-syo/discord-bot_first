#!/bin/bash

DIR="/home/yosyo/discord/discord-bot_first"
START_CMD="python3 main.py"

TMUX_SOCKET="notre-discord-bot"
TMUX_SESSION="notre-discord-bot"

send_cmd()
{
  cmd="$1"
  tmux -L $TMUX_SOCKET send-keys -t $TMUX_SESSION.0 "$cmd" Enter
  return $?
}

is_server_running()
{
  tmux -L $TMUX_SOCKET has-session -t $TMUX_SESSION > /dev/null 2>&1
  return $?
}

start_server()
{
  if is_server_running; then
    echo "Server already running..."
    return 1
  fi
  echo "Lancement du serveur dans une session tmux dédiée en cours..."
  tmux -L $TMUX_SOCKET new-session -c $DIR -s $TMUX_SESSION -d "$START_CMD"

  return $?
}

stop_server()
{
  if ! is_server_running; then
    echo "Le serveur n'est pas lancé"
    return 1
  fi

  echo "Signalement de l'arrêt du serveur aux joueurs..."
  send_cmd "title @a times 3 14 3"
  for i in {10..1}; do
    send_cmd "title @a subtitle {\"text\":\"$i secondes\",\"color\":\"gray\"}"
    send_cmd "title @a title {\"text\":\"Arrêt dans\",\"color\":\"dark_red\"}"
    sleep 1
  done

  echo "Éjection de tout les joueurs connectés"
  send_cmd "kickall"

  echo "Arrêt du serveur..."
  send_cmd "stop"
  if [ $? -ne 0 ]; then
    echo "Impossible d'envoyer un signal d'arrêt au serveur"
    return 1
  fi

  wait=0
  while is_server_running; do
    sleep 1
    wait=$((wait+1))
    if [ $wait -gt 60 ]; then
      echo "Impossible d'arrêter le serveur, délai dépassé"
      return 1
    fi
  done
  
  return $?
}

restart_server()
{
  echo "Redémarrage du serveur en cours..."
  stop_server
  sleep 1
  start_server
  return $?
}

reload_server()
{
  echo "Rechargement du serveur"
  send_cmd "reload"
  return $?
}

attach_session()
{
  if ! is_server_running; then
    echo "Impossible de s'attacher à la session tmux, le serveur minecraft n'est pas lancé"
    return 1
  fi

  tmux -L $TMUX_SOCKET attach-session -t $TMUX_SESSION
  return 0
}

case $1 in
  start)
    start_server
    exit $?
    ;;
  stop)
    stop_server
    exit $?
    ;;
  restart)
    restart_server
    exit $?
    ;;
  reload)
    reload_server
    exit $?
    ;;
  cmd)
    send_cmd "$2"
    exit $?
    ;;
  attach)
    attach_session
    exit $?
    ;;
  *)
    echo "Erreur: l'argument "$1" n'est pas une option valide "
    echo "Usage: $0 {start|stop|restart|reload|cmd|attach}"
    exit 2
    ;;
esac

