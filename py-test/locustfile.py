from locust import HttpLocust, TaskSet, task


class UserBehavior(TaskSet):

    #@task(1)
    #def login(self):
    #    self.client.post("/auth/login", {"username": "ellen_key", "password": "education"})

    @task(2)
    def profile(self):
        self.client.get("/profile", headers={"Authorization": "token-0"})


class WebsiteUser(HttpLocust):
    task_set = UserBehavior
    min_wait = 5000
    max_wait = 9000