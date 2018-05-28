import unittest
import requests
import uuid


def get_name():
    return str(uuid.uuid4()) + "@spawn.com"


class SgSrv:

    def __init__(self):
        self.endpoint = "http://localhost:8010"
        self.token = ""

    def register(self, user, psw):
        request = {
            "username": user,
            "password": psw
        }

        resp = requests.put(self.endpoint + '/auth/register', json=request)

        if resp.status_code != 200:
            return resp.text
        else:
            json = resp.json()
            self.token = json["token"]
            return None


class TestSimpleRest(unittest.TestCase):

    def setUp(self):
        pass

    def testRegister(self):
        api = SgSrv()

        err = api.register(get_name(), "password")

        self.assertIsNone(err)
        self.assertTrue(len(api.token) > 0)

    def testAlreadyRegistered(self):
        api = SgSrv()
        name = get_name()

        err = api.register(name, "password")
        self.assertIsNone(err)
        self.assertTrue(len(api.token) > 0)

        err = api.register(name, "password")
        self.assertIsNotNone(err)

    


if __name__ == '__main__':
    unittest.main()
