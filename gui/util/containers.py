import docker


class dockerContainer:
    def __init__(self, image_name, container_name, environment_vars=None, ports=None):
        self.container_name = container_name
        self.image_name = image_name
        self.environment_vars = environment_vars or {}
        self.ports = ports or {}
        self.client = docker.from_env()
        self.container = None

    def start(self):
        try:
            # Recreate the container cleanly if one already exists with this name.
            try:
                existing = self.client.containers.get(self.container_name)
                existing.remove(force=True)
                print(f"Container '{self.container_name}' removed before restart.")
            except docker.errors.NotFound:
                pass

            self.container = self.client.containers.run(
                image=self.image_name,
                name=self.container_name,
                environment=self.environment_vars,
                ports=self.ports,
                detach=True
            )
            print(f"Container '{self.container_name}' started successfully.")
            return self.container
        except docker.errors.APIError as e:
            print(f"Error starting image {self.image_name} for container '{self.container_name}': {e}")
            return None

    def stop(self):
        try:
            container = self.container or self.client.containers.get(self.container_name)
            container.stop()
            self.container = container
            print(f"Container '{self.container_name}' stopped successfully.")
            return True
        except docker.errors.NotFound:
            print(f"Container '{self.container_name}' does not exist.")
            return True
        except docker.errors.APIError as e:
            print(f"Error stopping container '{self.container_name}': {e}")
            return False

    def remove(self):
        try:
            container = self.container or self.client.containers.get(self.container_name)
            container.remove(force=True)
            self.container = None
            print(f"Container '{self.container_name}' removed successfully.")
            return True
        except docker.errors.NotFound:
            print(f"Container '{self.container_name}' does not exist.")
            self.container = None
            return True
        except docker.errors.APIError as e:
            print(f"Error removing container '{self.container_name}': {e}")
            return False

    def restart(self):
        if self.container:
            try:
                self.container.restart()
                print(f"Container '{self.container_name}' restarted successfully.")
            except docker.errors.APIError as e:
                print(f"Error restarting container '{self.container_name}': {e}")
        else:
            print(f"Container '{self.container_name}' is not running.")
    
    @staticmethod
    def staticStatus(container_name=None):
            docker_client = docker.from_env()
            try:                
                container = docker_client.containers.get(container_name)
                return container.status
            except docker.errors.NotFound:
                return "not running"
    
    def status(self):
        if self.container:
            try:
                self.container.reload()  # Refresh container data
                return self.container.status
            except docker.errors.APIError as e:
                print(f"Error checking status of container '{self.container_name}': {e}")
                return "error"
        elif not self.container:
            # Check if the container exists but is not running
            try:
                existing_container = self.client.containers.get(self.container_name)
                return existing_container.status
            except docker.errors.NotFound:
                 return "not running"   
        else:
            return "not running"
    

def normalize_container_name(name):
    return name.lower().replace(" ", "_").replace("-", "_")

