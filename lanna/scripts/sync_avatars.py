import os
import json
import urllib.request
import urllib.parse
import sys

# Set output encoding to UTF-8 to prevent console crash on non-ASCII characters
try:
    sys.stdout.reconfigure(encoding='utf-8')
except AttributeError:
    # Fallback for older python versions
    import codecs
    sys.stdout = codecs.getwriter("utf-8")(sys.stdout.detach())

# 1. Configuration
API_URL = 'https://siripaporn.lnw.mn/endpoints/users_api.php?action=getAll'
LOCAL_DIR = os.path.join(os.path.dirname(__file__), 'assets', 'images', 'profile')

# Ensure directory exists
os.makedirs(LOCAL_DIR, exist_ok=True)

print("Starting synchronization of profile images from server...")

try:
    # 2. Fetch users list
    req = urllib.request.Request(API_URL, headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req) as response:
        resp_data = json.loads(response.read().decode('utf-8'))
        
    users = resp_data.get('data', [])
    if not users:
        print("No users found on the server.")
        exit()
        
    print(f"Found {len(users)} users on the server. Checking avatars...")
    
    # Keep track of active filenames to clean up old ones
    active_filenames = []
    
    # 3. Download active avatars
    for user in users:
        avatar_url = user.get('avatar', '')
        user_id = user.get('user_id', 'unknown')
        username = user.get('username', 'unknown')
        
        if not avatar_url or 'filename=' not in avatar_url:
            continue
            
        # Extract filename from query parameter
        parsed_url = urllib.parse.urlparse(avatar_url)
        query_params = urllib.parse.parse_qs(parsed_url.query)
        filename = query_params.get('filename', [None])[0]
        
        if filename:
            active_filenames.append(filename)
            local_path = os.path.join(LOCAL_DIR, filename)
            
            # Download file if it doesn't exist locally
            if not os.path.exists(local_path):
                print(f"Downloading {filename} for user ID {user_id}...")
                urllib.request.urlretrieve(avatar_url, local_path)
            else:
                print(f"Image {filename} for user ID {user_id} already exists locally.")
                
    # 4. Clean up old profile images from local folder
    for local_file in os.listdir(LOCAL_DIR):
        if local_file.startswith('profile_') and local_file not in active_filenames:
            print(f"Cleaning up old unused local file: {local_file}")
            os.remove(os.path.join(LOCAL_DIR, local_file))
            
    print("Avatar synchronization completed successfully!")
    
except Exception as e:
    print("Error during synchronization:", e)
