from locust import HttpUser, task, between

class MyUser(HttpUser):
    host = "http://localhost:5000"  # Specify the base host
    wait_time = between(1, 2)  # Thời gian chờ giữa các request (1 - 3 giây)

    @task
    def test_endpoint_1(self):
        self.client.get("/")

