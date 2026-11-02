#!/bin/bash

set -e

PSQL="psql --username=freecodecamp --dbname=postgres --no-align --tuples-only --quiet -v ON_ERROR_STOP=1"

$PSQL <<'SQL'
SELECT 'CREATE DATABASE number_guess' WHERE NOT EXISTS (
  SELECT FROM pg_database WHERE datname = 'number_guess'
)\gexec
SQL

PSQL="psql --username=freecodecamp --dbname=number_guess --no-align --tuples-only --quiet -v ON_ERROR_STOP=1"

$PSQL <<'SQL'
SET client_min_messages = warning;
CREATE TABLE IF NOT EXISTS users (
  username VARCHAR(22) PRIMARY KEY,
  games_played INTEGER NOT NULL DEFAULT 0,
  best_game INTEGER
);
SQL

SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
echo "Enter your username:"
read -r USERNAME
while [[ -z "$USERNAME" || ${#USERNAME} -gt 22 ]]; do
  echo "Enter a username between 1 and 22 characters:"
  read -r USERNAME
done

USER_STATS=$($PSQL -v username="$USERNAME" <<'SQL'
SELECT games_played || ' ' || COALESCE(best_game::text, '')
FROM users
WHERE username = :'username';
SQL
)

if [[ -z "$USER_STATS" ]]; then
  echo "Welcome, $USERNAME! It looks like this is your first time here."
else
  read -r GAMES_PLAYED BEST_GAME <<< "$USER_STATS"
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

echo "Guess the secret number between 1 and 1000:"
GUESS_COUNT=0

while true; do
  read -r GUESS
  GUESS_COUNT=$((GUESS_COUNT + 1))

  if [[ ! "$GUESS" =~ ^-?[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  if (( GUESS < SECRET_NUMBER )); then
    echo "It's higher than that, guess again:"
  elif (( GUESS > SECRET_NUMBER )); then
    echo "It's lower than that, guess again:"
  else
    break
  fi
 done

echo "You guessed it in $GUESS_COUNT tries. The secret number was $SECRET_NUMBER. Nice job!"

$PSQL -v username="$USERNAME" -v guess_count="$GUESS_COUNT" <<'SQL'
INSERT INTO users (username, games_played, best_game)
VALUES (:'username', 1, :'guess_count')
ON CONFLICT (username) DO UPDATE
SET games_played = users.games_played + 1,
    best_game = CASE
      WHEN users.best_game IS NULL OR EXCLUDED.best_game < users.best_game
      THEN EXCLUDED.best_game
      ELSE users.best_game
    END;
SQL
