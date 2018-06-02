import unittest
import requests
import uuid


def get_name():
    return str(uuid.uuid4()) + "@spawn.com"


class SgClient:

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

    def login(self, user, psw):
        request = {
            "username": user,
            "password": psw
        }

        resp = requests.post(self.endpoint + '/auth/login', json=request)

        if resp.status_code != 200:
            return resp.text
        else:
            json = resp.json()
            self.token = json["token"]
            return None

    def whoami(self):
        resp = requests.get(self.endpoint + '/whoami', headers={"Authorization": self.token})

        if resp.status_code != 200:
            return True, resp.text
        else:
            return False, resp.json()

    def get_profile(self):
        resp = requests.get(self.endpoint + '/profile', headers={"Authorization": self.token})

        if resp.status_code != 200:
            return True, resp.text
        else:
            return False, resp.json()



class TestSimpleRest(unittest.TestCase):

    def setUp(self):
        pass

    def testRegister(self):
        api = SgClient()

        err = api.register(get_name(), "password")

        self.assertIsNone(err)
        self.assertTrue(len(api.token) > 0)

    def testAlreadyRegistered(self):
        api = SgClient()
        name = get_name()

        err = api.register(name, "password")
        self.assertIsNone(err)

        err = api.register(name, "password")
        self.assertIsNotNone(err)

        se = "Error: AppLogicError, alreadyRegistered({})".format(name)
        self.assertEqual(se, str(err))

    def testLogin(self):
        name = get_name()

        api1 = SgClient()
        err = api1.register(name, "password")
        self.assertIsNone(err)

        api2 = SgClient()
        err = api2.login(name, "password")
        self.assertIsNone(err)

        self.assertNotEqual(api1.token, api2.token)

    def testWhoami(self):
        name = get_name()

        api = SgClient()
        err = api.register(name, "password")
        self.assertIsNone(err)

        is_err, json = api.whoami()
        self.assertFalse(is_err)

        self.assertEqual(name, json["username"])

    def testGetProfile(self):
        name = get_name()

        api = SgClient()
        err = api.register(name, "password")
        self.assertIsNone(err)

        is_err, json = api.get_profile()
        self.assertFalse(is_err)

        self.assertEqual("UA", json["country"])
        self.assertEqual("", json["personal"]["firstName"])
        self.assertEqual("", json["personal"]["lastName"])



if __name__ == '__main__':
    unittest.main()
