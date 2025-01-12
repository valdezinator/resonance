from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from datetime import datetime
import sqlite3
from typing import List

app = FastAPI()

# Database setup
def init_db():
    conn = sqlite3.connect('recently_played.db')
    c = conn.cursor()
    c.execute('''
        CREATE TABLE IF NOT EXISTS recently_played (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            song_id TEXT NOT NULL,
            user_id TEXT NOT NULL,
            title TEXT NOT NULL,
            artist TEXT NOT NULL,
            image_url TEXT,
            audio_url TEXT,
            played_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(song_id, user_id)
        )
    ''')
    conn.commit()
    conn.close()

init_db()

class SongPlay(BaseModel):
    song_id: str
    user_id: str
    title: str
    artist: str
    image_url: str = None
    audio_url: str = None

@app.post("/track-play")
async def track_song_play(song_play: SongPlay):
    try:
        conn = sqlite3.connect('recently_played.db')
        c = conn.cursor()
        
        # Delete old entry if exists (to update timestamp)
        c.execute('DELETE FROM recently_played WHERE song_id = ? AND user_id = ?', 
                 (song_play.song_id, song_play.user_id))
        
        # Insert new play
        c.execute('''
            INSERT INTO recently_played (song_id, user_id, title, artist, image_url, audio_url)
            VALUES (?, ?, ?, ?, ?, ?)
        ''', (song_play.song_id, song_play.user_id, song_play.title, 
              song_play.artist, song_play.image_url, song_play.audio_url))
        
        conn.commit()
        return {"status": "success"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        conn.close()

@app.get("/recently-played/{user_id}")
async def get_recently_played(user_id: str, limit: int = 20):
    try:
        conn = sqlite3.connect('recently_played.db')
        c = conn.cursor()
        
        c.execute('''
            SELECT song_id, title, artist, image_url, audio_url, played_at
            FROM recently_played
            WHERE user_id = ?
            ORDER BY played_at DESC
            LIMIT ?
        ''', (user_id, limit))
        
        rows = c.fetchall()
        songs = []
        for row in rows:
            songs.append({
                "songs": {
                    "id": row[0],
                    "title": row[1],
                    "artist": row[2],
                    "image_url": row[3],
                    "audio_url": row[4]
                },
                "played_at": row[5]
            })
        
        return songs
    finally:
        conn.close()