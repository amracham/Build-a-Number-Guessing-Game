SET client_min_messages = warning;

CREATE TABLE IF NOT EXISTS users (
  username VARCHAR(22) PRIMARY KEY,
  games_played INTEGER NOT NULL DEFAULT 0,
  best_game INTEGER
);