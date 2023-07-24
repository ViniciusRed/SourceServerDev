import http.server
import socketserver
import os
import bz2
import shutil

# Obtain the Fastdl server port of the environment variablee
FASTDL_PORT = int(os.environ.get('FASTDL_PORT', 8080))

# Specify the directory where the files are downloaded
DIRECTORY = "./fastdl"
if not os.path.exists(DIRECTORY):
    os.makedirs(DIRECTORY)

# Function to create the "Maps" folder if it does not exist
def create_maps_folder():
    maps_folder = os.path.join("css/cstrike/download", "maps")
    if not os.path.exists(maps_folder):
        os.makedirs(maps_folder)

# Function to pre-compress files in Bzip2 and move the original file
def compress_files():
    create_maps_folder()
    for root, dirs, files in os.walk(DIRECTORY):
        for filename in files:
            if not filename.endswith(".bz2"):
                filepath = os.path.join(root, filename)
                compressed_path = filepath + ".bz2"
                if not os.path.exists(compressed_path):
                    with open(filepath, "rb") as file_in, bz2.open(compressed_path, "wb") as file_out:
                        file_out.writelines(file_in)

                    # Move the original file after compression
                    move_path = os.path.join("css/cstrike/download/maps", filename)
                    shutil.move(filepath, move_path)

# Pre-compress files and move after compression
compress_files()

class FastDownloadHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        # Obtain the absolute path of the file that the customer is requesting
        path = self.translate_path(self.path)

        # Checks if the compacted file or the uncomputed file exists
        compressed_path = path + ".bz2"
        if os.path.isfile(compressed_path):
            # Send the compacted file to the customer
            self.send_response(200)
            self.send_header("Content-type", "application/x-bzip2")
            self.send_header("Content-Encoding", "bzip2")
            self.send_header("Content-Disposition", f"attachment; filename={os.path.basename(path)}.bz2")
            self.send_header("Content-Length", os.path.getsize(compressed_path)) # type: ignore
            self.end_headers()

            with open(compressed_path, "rb") as file:
                self.copyfile(file, self.wfile)
        elif os.path.isfile(path):
            # Send the uncompressed file to the client
            self.send_response(200)
            self.send_header("Content-type", self.guess_type(path))
            self.send_header("Content-Length", os.path.getsize(path)) # type: ignore
            self.end_headers()

            with open(path, "rb") as file:
                self.copyfile(file, self.wfile)
        else:
            # If the file does not exist, return erro 404 - Not Found
            self.send_error(404)

try:
    with socketserver.TCPServer(("", FASTDL_PORT), FastDownloadHandler) as httpd:
        print(f"FastDl running at the door {FASTDL_PORT}. To download, access http://hostip:{FASTDL_PORT}/" )
        httpd.serve_forever()
except OSError as e:
    print(f"Error: The port {FASTDL_PORT} is already in use by another process.")