import os
import json
import urllib.request
import urllib.parse
import sys
import time

# Set output encoding to UTF-8 to prevent console crash on non-ASCII characters
try:
    sys.stdout.reconfigure(encoding='utf-8')
except AttributeError:
    # Fallback for older python versions
    import codecs
    sys.stdout = codecs.getwriter("utf-8")(sys.stdout.detach())

# Configuration
API_URL = 'https://siripaporn.lnw.mn/endpoints/users_api.php?action=getAll'
LOCAL_DIR = os.path.join(os.path.dirname(__file__), 'assets', 'images', 'profile')

# Ensure directory exists
os.makedirs(LOCAL_DIR, exist_ok=True)

print("="*60)
print("  LANNA Real-time Avatar Sync Watcher is Running  ")
print("  Press Ctrl+C to exit this background watcher  ")
print("="*60)

last_active_filenames = None

while True:
    try:
        # Fetch current users from server
        req = urllib.request.Request(API_URL, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response:
            resp_data = json.loads(response.read().decode('utf-8'))
            
        users = resp_data.get('data', [])
        active_filenames = []
        
        for user in users:
            avatar_url = user.get('avatar', '')
            if not avatar_url or 'filename=' not in avatar_url:
                continue
                
            parsed_url = urllib.parse.urlparse(avatar_url)
            query_params = urllib.parse.parse_qs(parsed_url.query)
            filename = query_params.get('filename', [None])[0]
            if filename:
                active_filenames.append(filename)
        
        # Sort to ensure comparison is consistent
        active_filenames.sort()
        
        # Initialize or detect changes
        if last_active_filenames is None:
            last_active_filenames = active_filenames
            # Run initial sync on start
            for user in users:
                avatar_url = user.get('avatar', '')
                user_id = user.get('user_id', 'unknown')
                if not avatar_url or 'filename=' not in avatar_url:
                    continue
                parsed_url = urllib.parse.urlparse(avatar_url)
                query_params = urllib.parse.parse_qs(parsed_url.query)
                filename = query_params.get('filename', [None])[0]
                if filename:
                    local_path = os.path.join(LOCAL_DIR, filename)
                    if not os.path.exists(local_path):
                        print(f"[Initial] Downloading {filename} for user ID {user_id}...")
                        urllib.request.urlretrieve(avatar_url, local_path)
            
            # Clean up old ones on startup too
            for local_file in os.listdir(LOCAL_DIR):
                if local_file.startswith('profile_') and local_file not in active_filenames:
                    print(f"[Initial] Deleting old unused local file: {local_file}")
                    try:
                        os.remove(os.path.join(LOCAL_DIR, local_file))
                    except Exception as e:
                        pass
                        
            print("Initial sync complete. Watching for database changes in real-time...")
            
        elif active_filenames != last_active_filenames:
            print("\n[Change Detected] Syncing profile images with database...")
            
            # Download new ones
            for user in users:
                avatar_url = user.get('avatar', '')
                user_id = user.get('user_id', 'unknown')
                if not avatar_url or 'filename=' not in avatar_url:
                    continue
                parsed_url = urllib.parse.urlparse(avatar_url)
                query_params = urllib.parse.parse_qs(parsed_url.query)
                filename = query_params.get('filename', [None])[0]
                if filename:
                    local_path = os.path.join(LOCAL_DIR, filename)
                    if not os.path.exists(local_path):
                        print(f"-> Downloading new file: {filename} for user ID {user_id}...")
                        urllib.request.urlretrieve(avatar_url, local_path)
            
            # Clean up old ones
            for local_file in os.listdir(LOCAL_DIR):
                if local_file.startswith('profile_') and local_file not in active_filenames:
                    print(f"-> Deleting old unused local file: {local_file}")
                    try:
                        os.remove(os.path.join(LOCAL_DIR, local_file))
                    except Exception as e:
                        pass
                        
            last_active_filenames = active_filenames
            print("Sync complete. Resume watching...")
            
    except Exception as e:
        print("Error during watch sync loop:", e)
        
    time.sleep(3)
