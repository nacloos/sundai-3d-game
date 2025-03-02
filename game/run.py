import subprocess
import threading
import time

def run_godot_with_timeout():
    try:
        # Start the godot process and capture output
        process = subprocess.Popen(
            ["godot"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1
        )
        
        output = []
        
        # Function to read output from a pipe
        def read_pipe(pipe):
            for line in pipe:
                output.append(line)
        
        # Start output collection threads
        stdout_thread = threading.Thread(target=read_pipe, args=(process.stdout,))
        stderr_thread = threading.Thread(target=read_pipe, args=(process.stderr,))
        stdout_thread.daemon = True
        stderr_thread.daemon = True
        stdout_thread.start()
        stderr_thread.start()
        
        # Wait for 2 seconds
        time.sleep(2)
        
        # Kill the process if it's still running
        if process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=1)  # Give it a second to terminate gracefully
            except subprocess.TimeoutExpired:
                process.kill()  # Force kill if it doesn't terminate
        
        # Get any remaining output
        remaining_stdout, remaining_stderr = process.communicate()
        if remaining_stdout:
            output.append(remaining_stdout)
        if remaining_stderr:
            output.append(remaining_stderr)
            
        # Print collected output
        print("Collected output:")
        print("".join(output))
        
    except Exception as e:
        print(f"Error occurred: {e}")

if __name__ == "__main__":
    run_godot_with_timeout()
